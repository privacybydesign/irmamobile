import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/issuance/issuance_permission.dart";
import "package:yivi_core/src/screens/session/layout/session_layout.dart";
import "package:yivi_core/src/screens/session/result/issuance_success_screen.dart";
import "package:yivi_core/src/widgets/layout/legacy_material_bridge.dart";
import "package:yivi_core/src/widgets/sheet/form_sheet_frame.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";

// A 13" iPad held upright: the tablet columns. Held sideways a tablet uses
// the layout of a phone held sideways.
const _tablet = Size(1032, 1376);
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

    testWidgets("tablet: the issuer, the question and the button left, the "
        "cards right", (tester) async {
      await pump(tester, _tablet, screen());

      expect(find.byType(SidewaysLayout), findsOneWidget);
      final question = tester.getRect(
        find.byKey(const Key("issuance_question")),
      );
      final values = tester.getRect(find.byKey(const Key("issuance_card_0")));
      final add = tester.getRect(find.byKey(const Key("bottom_bar_primary")));
      final panel = tester.getRect(find.byKey(const Key("issuance_panel")));
      expect(values.left, greaterThan(question.right));
      expect(values.left, greaterThan(add.right));
      // The way on at the foot of the left column, under the question; no
      // Cancel (the close button declines).
      expect(add.top, greaterThan(question.bottom));
      expect(add.bottom, closeTo(panel.bottom, 80));
      expect(find.byKey(const Key("bottom_bar_secondary")), findsNothing);
    });

    testWidgets("phone: one column, the button in the bottom bar", (
      tester,
    ) async {
      await pump(tester, _phone, screen());

      expect(find.byType(SidewaysLayout), findsNothing);
      final question = tester.getRect(
        find.byKey(const Key("issuance_question")),
      );
      final values = tester.getRect(find.byKey(const Key("issuance_card_0")));
      expect(values.top, greaterThan(question.bottom));
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
    testWidgets("$name, tablet: the picture and the button at the left, "
        "the words at the right", (tester) async {
      await pump(tester, _tablet, screen);

      expect(find.byType(SidewaysLayout), findsOneWidget);
      final panel = tester.getRect(find.byKey(const Key("result_panel")));
      final rect = tester.getRect(button);
      expect(panel.contains(rect.center), isTrue);
      expect(rect.width, lessThan(400));
      expect(rect.bottom, greaterThan(_tablet.height - 120));
    });
  }

  testWidgets("a Yivi sheet is a centred dialog on tablet", (tester) async {
    await pump(
      tester,
      _tablet,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showTitledSheet(
                context: context,
                titleKey: "share.pick.title",
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
    // A form sheet of 540, as on an iPad.
    final width = FormSheetFrame.width(_tablet.width);
    expect(width, 540);
    expect(options.left, greaterThan((_tablet.width - width) / 2 - 1));
    expect(options.right, lessThan((_tablet.width + width) / 2 + 1));
  });
}
