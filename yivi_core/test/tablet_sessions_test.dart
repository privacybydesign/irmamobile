import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_columns.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

const _tablet = Size(1180, 820);
const _phone = Size(390, 844);

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> pump(
    WidgetTester tester,
    Size size,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      overrides: overrides,
      home: LegacyMaterialBridge(child: home),
    );
    await settle(tester);
    await tester.pumpAndSettle();
  }

  final ticket = testCredential(
    type: "pbdf.pbdf.ticket",
    hash: "ticket",
    name: "Ticket",
    attributes: [stringAttr("seat", "12A")],
  );

  group("issuance permission", () {
    Widget screen() => IssuancePermission(
      issuedCredentials: [ticket],
      onDismiss: () {},
      onGivePermission: () {},
    );

    testWidgets("tablet: the card left, what you receive and the buttons "
        "right", (tester) async {
      await pump(tester, _tablet, screen());

      expect(find.byType(SessionColumns), findsOneWidget);
      // The big card; the group of values has a mini one too.
      final card = tester.getRect(find.byType(CredentialCardArt).first);
      final receive = tester.getRect(find.text("You will receive"));
      final add = tester.getRect(find.byKey(const Key("bottom_bar_primary")));
      expect(receive.left, greaterThan(card.right));
      expect(add.left, greaterThan(card.right));
      // The buttons follow the content instead of sitting at the bottom.
      expect(add.bottom, lessThan(_tablet.height - 100));
    });

    testWidgets("phone: one column, the buttons in the bottom bar", (
      tester,
    ) async {
      await pump(tester, _phone, screen());

      expect(find.byType(SessionColumns), findsNothing);
      // The big card; the group of values has a mini one too.
      final card = tester.getRect(find.byType(CredentialCardArt).first);
      final receive = tester.getRect(find.text("You will receive"));
      expect(receive.top, greaterThan(card.bottom));
    });
  });

  for (final (name, screen, button) in [
    (
      "the call",
      const CallInfoScreen(otherParty: "Gemeente", phoneNumber: "+31201234567"),
      find.text("Call Gemeente"),
    ),
    (
      "a result",
      IssuanceSuccessScreen(credentials: [ticket], onDismiss: (_) {}),
      find.byKey(const Key("ok_button")),
    ),
  ]) {
    testWidgets("$name, tablet: one centred column, the button under the "
        "text", (tester) async {
      await pump(tester, _tablet, screen);

      expect(find.byType(SessionCentred), findsOneWidget);
      final rect = tester.getRect(button);
      expect(rect.center.dx, closeTo(_tablet.width / 2, 1));
      expect(rect.width, lessThan(400));
      expect(rect.bottom, lessThan(_tablet.height - 100));
    });
  }

  group("change choice", () {
    Future<void> open(WidgetTester tester, Size size) async {
      await pump(
        tester,
        size,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => pushSessionSubscreen(
                  context,
                  const Scaffold(body: Center(child: Text("choices"))),
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
    }

    testWidgets("tablet: a centred dialog", (tester) async {
      await open(tester, _tablet);
      expect(find.byType(SessionDialogFrame), findsOneWidget);
      final rect = tester.getRect(find.text("choices"));
      expect(rect.center.dx, closeTo(_tablet.width / 2, 1));
    });

    testWidgets("phone: a page", (tester) async {
      await open(tester, _phone);
      expect(find.byType(SessionDialogFrame), findsNothing);
      expect(find.text("choices"), findsOneWidget);
    });
  });

  testWidgets("a Yivi sheet is a centred dialog on tablet", (tester) async {
    await pump(
      tester,
      _tablet,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showTitledGlassSheet(
                context: context,
                titleKey: "share.sheet.pick_card",
                child: const SizedBox(height: 200, child: Text("options")),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final options = tester.getRect(find.text("options"));
    expect(options.left, greaterThan((_tablet.width - 520) / 2 - 1));
    expect(options.right, lessThan((_tablet.width + 520) / 2 + 1));
  });
}
