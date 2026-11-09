import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/glass_dialog.dart";
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

    testWidgets("the issuer, the question and the button in the panel, "
        "the values at the right", (tester) async {
      await pump(
        tester,
        IssuancePermission(
          issuedCredentials: [ticket],
          onDismiss: () {},
          onGivePermission: () {},
        ),
      );
      final question = find.byKey(const Key("issuance_question"));
      expect(find.descendant(of: panel, matching: question), findsOneWidget);
      expect(find.descendant(of: column, matching: find.text("12A")), findsOne);
      // No bottom bar: the button is at the bottom of the panel.
      expect(find.byType(IrmaBottomBarBase), findsNothing);
      final add = find.byKey(const Key("bottom_bar_primary"));
      expect(find.descendant(of: panel, matching: add), findsOneWidget);
      expect(
        tester.getRect(add).top,
        greaterThan(tester.getRect(question).bottom),
      );
      // No Cancel: the close button declines.
      expect(find.byKey(const Key("bottom_bar_secondary")), findsNothing);
      // The values at most 420 wide.
      expect(
        tester.getRect(find.byKey(const Key("issuance_card_0"))).width,
        lessThanOrEqualTo(420),
      );
      // Close in the corner, beside the column, clear of the rounded corner.
      final close = tester.getRect(find.byType(IrmaCloseButton));
      expect(close.right, 874 - 24);
      expect(close.top, 24);
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
      expect(find.text("IN YOUR APP"), findsOneWidget);
    });
  });

  testWidgets("shared: the pile with its check left, the words and Done "
      "right", (tester) async {
    await pump(
      tester,
      DisclosureFeedbackScreen(
        otherParty: "Webshop",
        isSignatureSession: false,
        // On another device: with Done.
        onOtherDevice: true,
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
    final pile = tester.getRect(find.byKey(const Key("share_done_pile")));
    final check = tester.getRect(find.byKey(const Key("share_done_check")));
    final title = tester.getRect(find.byKey(const Key("share_done_title")));
    final ok = tester.getRect(find.byKey(const Key("ok_button")));
    // The check on the pile's corner.
    expect(check.right, lessThanOrEqualTo(pile.right + 4));
    expect(check.top, closeTo(pile.top, 4));
    // The words and the button in the right column, the button under them.
    expect(title.left, greaterThan(pile.right));
    expect(ok.left, title.left);
    expect(
      ok.top,
      greaterThan(
        tester.getRect(find.byKey(const Key("share_done_text"))).bottom,
      ),
    );
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
