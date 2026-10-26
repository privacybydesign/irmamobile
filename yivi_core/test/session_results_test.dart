import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/pairing_required.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/card_pile.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "missing_data_fixtures.dart";
import "support/pump_translated.dart";

// The screens at the end of a session: cards added (also inside a
// request), shared, the call screen and the pairing code.

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

/// The repository and preferences a whole [SessionScreen] needs.
Future<List<Override>> _app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  final repo = IrmaRepository(client: _SilentBridge(), preferences: prefs);
  addTearDown(repo.close);
  return [
    preferencesProvider.overrideWithValue(prefs),
    irmaRepositoryProvider.overrideWithValue(repo),
  ];
}

class _EmptyWallet extends SchemalessCredentialOrderController {
  @override
  Future<List<Credential>> build() async => const [];
}

Attribute _value(String path, String name, String value) => Attribute(
  claimPath: [path],
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: value),
);

SelectableCredentialInstance _shared(
  String id,
  String name, {
  int? left,
  List<Attribute> attributes = const [],
}) => SelectableCredentialInstance(
  credentialId: id,
  hash: "hash-$id",
  name: name,
  issuer: testParty("Yivi"),
  format: CredentialFormat.idemix,
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  batchInstanceCountRemaining: left,
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        schemalessCredentialOrderControllerProvider.overrideWith(
          _EmptyWallet.new,
        ),
        ...overrides,
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: home,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  group("cards added", () {
    testWidgets("one card on its own: its name, and OK", (tester) async {
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("email")],
          onDismiss: (_) {},
        ),
      );

      expect(find.text("Cred email has been added to Yivi."), findsOneWidget);
      expect(find.byKey(const Key("received_check")), findsOneWidget);
      expect(find.byType(CardPile), findsNothing);
      expect(find.text("OK"), findsOneWidget);
    });

    testWidgets("several cards: the pile with one check", (tester) async {
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("a"), testCredential("b")],
          onDismiss: (_) {},
        ),
      );

      expect(find.byType(CardPile), findsOneWidget);
      expect(find.byKey(const Key("received_check")), findsOneWidget);
      expect(
        find.text("These 2 cards have been added to Yivi."),
        findsOneWidget,
      );
    });

    testWidgets("sideways beside a side panel: the pile and its check stay "
        "in the panel", (tester) async {
      // An iPhone Duo unfolded, held sideways: the control bar at the right.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(951, 669)
        ..padding = const FakeViewPadding(right: 84, bottom: 34);
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("a"), testCredential("b")],
          onDismiss: (_) {},
        ),
      );

      final panel = tester.getRect(find.byKey(const Key("issuance_panel")));
      final check = tester.getRect(find.byKey(const Key("received_check")));
      expect(check.right, lessThanOrEqualTo(panel.right));
      // On the corner of the front card, as on a single card.
      final front = tester.getRect(
        find
            .descendant(
              of: find.byType(CardPile),
              matching: find.byType(CredentialCardArt),
            )
            .last,
      );
      expect(check.center.dx, moreOrLessEquals(front.right - 14, epsilon: 8));
      expect(check.center.dy, moreOrLessEquals(front.top + 10, epsilon: 8));
    });

    testWidgets("inside a request: next comes the request", (tester) async {
      var dismissed = 0;
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("email")],
          backTo: "Webshop",
          onDismiss: (_) => dismissed++,
        ),
      );

      expect(
        find.text("Cred email has been added to Yivi. Next, back to Webshop."),
        findsOneWidget,
      );
      await tester.tap(find.text("Back to Webshop"));
      expect(dismissed, 1);
    });

    testWidgets("a nested session shows it, with its request's requestor", (
      tester,
    ) async {
      const nestedId = 2;
      await _pump(
        tester,
        const SessionScreen(sessionId: nestedId, hasUnderlyingSession: true),
        overrides: [
          ...(await tester.runAsync(_app))!,
          sessionStateProvider(nestedId).overrideWith(
            (ref) => Stream.value(
              SessionState(
                id: nestedId,
                protocol: "irma",
                type: SessionType.issuance,
                status: SessionStatus.success,
                requestor: testParty("Issuer"),
                offeredCredentials: [testCredential("email")],
              ),
            ),
          ),
          underlyingDisclosureProvider(
            nestedId,
          ).overrideWith((ref) => Stream.value(testSession(steps: const []))),
        ],
      );

      expect(find.byType(IssuanceSuccessScreen), findsOneWidget);
      expect(find.text("Back to Test Verifier"), findsOneWidget);
    });
  });

  group("shared", () {
    Future<void> pump(
      WidgetTester tester, {
      List<SelectableCredentialInstance> shared = const [],
      bool signature = false,
      bool onOtherDevice = false,
      VoidCallback? onDone,
    }) => _pump(
      tester,
      DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.success,
        otherParty: "Webshop",
        isSignatureSession: signature,
        onOtherDevice: onOtherDevice,
        shared: shared,
        onDismiss: (_) => onDone?.call(),
      ),
    );

    final email = _shared(
      "email",
      "Email address",
      attributes: [_value("email", "Email address", "anna@example.com")],
    );

    testWidgets("with whom, and exactly what", (tester) async {
      var done = 0;
      await pump(tester, shared: [email], onDone: () => done++);

      expect(find.byKey(const Key("share_done_check")), findsOneWidget);
      expect(find.text("Shared with Webshop"), findsOneWidget);
      expect(
        find.text(
          "Webshop received only what is listed here. You can find this in "
          "Activity.",
        ),
        findsOneWidget,
      );
      expect(find.text("anna@example.com"), findsOneWidget);

      await tester.tap(find.text("Done"));
      expect(done, 1);
    });

    testWidgets("on another device: continue there", (tester) async {
      await pump(tester, shared: [email], onOtherDevice: true);

      expect(
        find.textContaining("Continue on the other device."),
        findsOneWidget,
      );
    });

    testWidgets("a signature", (tester) async {
      await pump(tester, shared: [email], signature: true);

      expect(find.text("Signed and shared"), findsOneWidget);
    });

    testWidgets("nothing shared", (tester) async {
      await pump(tester);

      expect(find.text("Done"), findsNWidgets(2));
      expect(
        find.text(
          "Webshop received no data from you. You can find this in Activity.",
        ),
        findsOneWidget,
      );
    });

    testWidgets("a card's last use: one note after the list, no chip", (
      tester,
    ) async {
      await pump(tester, shared: [_shared("age", "Age limits", left: 1)]);

      expect(find.byKey(const Key("share_done_last_use")), findsOneWidget);
      expect(
        find.text(
          "That was the last time this age limits could be shared. Add a new "
          "one when you need it again.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key("shared_card_chip")), findsNothing);
      expect(find.byKey(const Key("shared_card_note")), findsNothing);
    });
  });

  testWidgets("call: shared, now call, with the number", (tester) async {
    var called = 0;
    await _pump(
      tester,
      CallInfoScreen(
        otherParty: "Gemeente",
        phoneNumber: "+31612345678",
        onContinue: () => called++,
      ),
    );

    expect(find.text("Shared. Now call Gemeente"), findsOneWidget);
    expect(find.text("+31612345678"), findsOneWidget);
    await tester.tap(find.text("Call Gemeente"));
    expect(called, 1);
  });

  testWidgets("pairing: who asks, and what the code is for", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("Webshop"),
        onDismiss: () {},
      ),
      // The spinner waits for the website and never settles.
      settle: false,
    );

    expect(find.text("Enter this code on the website"), findsOneWidget);
    expect(
      find.textContaining("Webshop shows a field for it."),
      findsOneWidget,
    );
    expect(find.byKey(const Key("pairing_code_box_3")), findsOneWidget);
  });

  testWidgets("pairing: a requestor without a name is unknown", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("", verified: false),
        onDismiss: () {},
      ),
      settle: false,
    );

    // The shield and the general instruction, not an empty card.
    expect(find.byType(RequestorCard), findsNothing);
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    expect(find.textContaining("shows a field for it"), findsNothing);
    expect(find.byKey(const Key("pairing_code_box_3")), findsOneWidget);
  });

  testWidgets("pairing: a named requestor has its card", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("Webshop"),
        onDismiss: () {},
      ),
      settle: false,
    );
    expect(find.byType(RequestorCard), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
  });
}
