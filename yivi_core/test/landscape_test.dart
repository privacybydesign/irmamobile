import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/shared_card_tile.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/glass_dialog.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/irma_bottom_bar_base.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "helpers/credential_factory.dart";
import "missing_data_fixtures.dart" show testParty;
import "support/onboarding_v2_harness.dart";

// An iPhone 17 Pro on its side: the notch side's safe area left and right,
// the home indicator below.
const _phone = Size(874, 402);
const _insets = FakeViewPadding(left: 62, right: 62, bottom: 21);

void main() {
  late IrmaRepository repo;

  setUp(() async {
    // The app's bridge to Go says it is ready, also after a test is over.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("irma.app/irma_mobile_bridge"),
          (_) async => null,
        );
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = _phone
      ..padding = _insets;
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
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
    final panel = find.byKey(const Key("issuance_panel"));
    final column = find.byKey(const Key("issuance_scroll_view"));

    testWidgets("the card and buttons in the panel, the question and the "
        "values at the right", (tester) async {
      await pump(
        tester,
        IssuancePermission(
          issuedCredentials: [ticket],
          onDismiss: () {},
          onGivePermission: () {},
        ),
      );
      final question = find.byKey(const Key("issuance_question"));
      expect(find.descendant(of: column, matching: question), findsOneWidget);
      expect(find.descendant(of: panel, matching: question), findsNothing);
      expect(
        find.descendant(of: column, matching: find.text("You will receive")),
        findsOneWidget,
      );
      final card = find.descendant(
        of: panel,
        matching: find.byType(CredentialCardArt),
      );
      expect(card, findsOneWidget);
      // No bottom bar: the buttons are at the bottom of the panel.
      expect(find.byType(IrmaBottomBarBase), findsNothing);
      final add = find.byKey(const Key("bottom_bar_primary"));
      expect(find.descendant(of: panel, matching: add), findsOneWidget);
      // Cancel is the text button, without a fill.
      expect(
        tester
            .widget<PillButton>(find.byKey(const Key("bottom_bar_secondary")))
            .style,
        PillStyle.text,
      );
      // The card in the middle of the room above the buttons.
      final room = tester.getRect(panel).top + 16;
      final above = tester.getRect(add).top - 16;
      final middle = (room + above) / 2;
      expect(tester.getRect(card).center.dy, closeTo(middle, 24));
      // Close in the corner, beside the column.
      expect(tester.getRect(find.byType(IrmaCloseButton)).right, 874 - 16);
    });

    testWidgets("success: the card and OK in the panel, the words and "
        "what is now in the app right", (tester) async {
      await pump(
        tester,
        IssuanceSuccessScreen(credentials: [ticket], onDismiss: (_) {}),
      );
      final panel = find.byKey(const Key("issuance_panel"));
      expect(
        find.byKey(const Key("issuance_success_landscape")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.byType(CredentialCardArt)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.byKey(const Key("ok_button")),
        ),
        findsOneWidget,
      );
      final card = tester.getRect(find.byType(CredentialCardArt).first);
      final title = tester.getRect(find.text("Success"));
      expect(title.left, greaterThan(card.right));
      expect(find.text("In your app"), findsOneWidget);
    });
  });

  testWidgets("shared: the check and Done left, what was shared right, "
      "the full height", (tester) async {
    await pump(
      tester,
      DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.success,
        otherParty: "Webshop",
        isSignatureSession: false,
        onOtherDevice: false,
        shared: [
          SelectableCredentialInstance(
            credentialId: "email",
            hash: "hash-email",
            name: "Email address",
            issuer: testParty("Yivi"),
            format: CredentialFormat.idemix,
            attributes: [stringAttr("email", "s@werk.example")],
            revoked: false,
            revocationSupported: false,
          ),
        ],
        onDismiss: (_) {},
      ),
    );
    final check = tester.getRect(find.byKey(const Key("share_done_check")));
    final tile = tester.getRect(find.byType(SharedCardTile));
    expect(tile.left, greaterThan(check.right));
    final ok = tester.getRect(find.byKey(const Key("ok_button")));
    // In the panel under the check, as on the issuance success.
    expect(ok.right, lessThan(tile.left));
    expect(ok.top, greaterThan(check.bottom));
    // The list has the right column to the bottom: no bar under it.
    final list = tester.getRect(find.byKey(const Key("issuance_scroll_view")));
    expect(list.bottom, 402);
  });

  testWidgets("a dialog: wider, its buttons side by side, the first right", (
    tester,
  ) async {
    await pump(
      tester,
      const GlassDialog(
        title: "Share with a party Yivi doesn't know?",
        message: "They get the data on this page.",
        actions: [
          SizedBox(key: Key("safe"), height: 48, child: Text("Don't share")),
          SizedBox(key: Key("risky"), height: 48, child: Text("Share anyway")),
        ],
      ),
    );
    final safe = tester.getRect(find.byKey(const Key("safe")));
    final risky = tester.getRect(find.byKey(const Key("risky")));
    expect(safe.top, risky.top);
    expect(safe.left, greaterThan(risky.right));
  });
}
