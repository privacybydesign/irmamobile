import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/error/error_screen.dart";
import "package:yivi_core/src/screens/error/no_internet_screen.dart";
import "package:yivi_core/src/screens/help/help_screen.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

final _log = LogInfo(
  type: LogType.disclosure,
  time: DateTime.utc(2026, 10, 15, 14, 32),
  issuanceLog: null,
  signedMessageLog: null,
  removalLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: [
      LogCredential(
        credentialId: "pbdf.sidn-pbdf.email",
        formats: const [CredentialFormat.idemix],
        name: "Email address",
        issuer: _party("Yivi"),
        attributes: [stringAttr("email", "s.devries@werk.example")],
        revoked: false,
        revocationSupported: false,
      ),
    ],
    verifier: _party("Webshop Noord"),
  ),
);

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  /// Every text of the page lies below the floating app bar and above the
  /// bottom bar when the page has not been scrolled: the content starts
  /// below the bars even though it can scroll underneath them.
  Future<void> expectClearOfBars(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: <Override>[irmaRepositoryProvider.overrideWithValue(repo)],
      home: LegacyMaterialBridge(child: screen),
    );
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 600));

    final bar = find.byKey(const Key("irma_app_bar"));
    final barBottom = bar.evaluate().isEmpty ? 0.0 : tester.getRect(bar).bottom;
    final bottomBars = [
      find.byKey(const Key("bottom_bar_primary")),
      find.byKey(const Key("bottom_bar_secondary")),
    ].where((f) => f.evaluate().isNotEmpty).toList();
    final bottomTop = bottomBars.isEmpty
        ? double.infinity
        : bottomBars
              .map((f) => tester.getRect(f).top)
              .reduce((a, b) => a < b ? a : b);

    for (final text in find.byType(Text).evaluate()) {
      final finder = find.byElementPredicate((e) => e == text);
      final inBar = find
          .ancestor(of: finder, matching: bar)
          .evaluate()
          .isNotEmpty;
      final inBottom = bottomBars.any(
        (b) =>
            find.ancestor(of: finder, matching: b).evaluate().isNotEmpty ||
            b.evaluate().first == text,
      );
      if (inBar || inBottom) continue;
      final rect = tester.getRect(finder);
      // Off-screen content further down is allowed: it scrolls into view.
      if (rect.top >= 844) continue;
      expect(
        rect.top,
        greaterThanOrEqualTo(barBottom - 0.5),
        reason: "'${(text.widget as Text).data}' starts under the app bar",
      );
    }

    // Long pages run on under the buttons, but their end scrolls clear.
    final scrollable = find.byType(Scrollable);
    if (bottomBars.isNotEmpty && scrollable.evaluate().isNotEmpty) {
      final position = tester.state<ScrollableState>(scrollable.first).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final lowest = find
          .byType(Text)
          .evaluate()
          .where(
            (e) => !bottomBars.any(
              (b) => find
                  .ancestor(
                    of: find.byElementPredicate((x) => x == e),
                    matching: b,
                  )
                  .evaluate()
                  .isNotEmpty,
            ),
          )
          .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
          .where((r) => r.top < 844)
          .map((r) => r.bottom)
          .fold<double>(0, (a, b) => a > b ? a : b);
      expect(
        lowest,
        lessThanOrEqualTo(bottomTop + 0.5),
        reason: "the end of the page cannot scroll clear of the buttons",
      );
    }
  }

  final screens = <String, Widget Function()>{
    "help": () => HelpScreen(),
    "activity detail": () =>
        ActivityDetailsScreen(args: ActivityDetailsScreenArgs(logEntry: _log)),
    "error": () => ErrorScreen(onTapClose: () {}, details: "details"),
    "no internet": () => NoInternetScreen(onTapClose: () {}),
    "call info": () => CallInfoScreen(otherParty: "Gemeente"),
    "add data permission": () => IssuancePermission(
      issuedCredentials: [
        testCredential(
          type: "pbdf.sidn-pbdf.email",
          hash: "email",
          name: "Email address",
          attributes: [stringAttr("email", "s.devries@werk.example")],
        ),
      ],
      onDismiss: () {},
      onGivePermission: () {},
    ),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets("$name: content starts clear of the bars", (tester) async {
      await expectClearOfBars(tester, screen());
    });
  }

  testWidgets("the app bar insets its buttons 16 and does not clip", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: IrmaAppBar(titleString: "Title"),
        body: const SizedBox.expand(),
      ),
    );
    await settle(tester);

    final back = tester.getRect(find.byKey(const Key("irma_app_bar_leading")));
    expect(back.left, 16);
    expect(back.size, const Size(44, 44));
    expect(back.top, 16);
    expect(
      find.descendant(
        of: find.byKey(const Key("irma_app_bar")),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
  });
}
