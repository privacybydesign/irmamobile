import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/widgets/contact_widgets.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/onboarding_v2_harness.dart";

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
    Widget home, {
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    // Pinput needs the core Material the app's builder puts in.
    await pumpHome(
      tester,
      repo: repo,
      home: LegacyMaterialBridge(child: home),
    );
    // Pinput's blinking cursor never settles.
    settle
        ? await tester.pumpAndSettle()
        : await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets("the code boxes turn red with the error below them", (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    await pump(
      tester,
      Scaffold(
        body: Column(
          children: [
            ContactCodeField(
              fieldKey: const Key("code"),
              controller: controller,
              focusNode: focus,
              length: 6,
              invalid: true,
            ),
            const ContactCodeError(
              "email_issuance.verify_code.invalid_code_error",
            ),
          ],
        ),
      ),
      settle: false,
    );

    expect(find.text("Verification code"), findsOneWidget);
    expect(find.text("Invalid code, try again..."), findsOneWidget);

    final pinput = tester.widget<Pinput>(find.byKey(const Key("code")));
    expect(pinput.forceErrorState, isTrue);
    expect(pinput.defaultPinTheme!.width, 48);
    expect(pinput.defaultPinTheme!.height, 60);
  });
}
