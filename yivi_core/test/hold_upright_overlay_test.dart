import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:native_device_orientation/native_device_orientation.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/hold_upright_overlay.dart";
import "package:yivi_core/src/theme/theme.dart";

const _prompt = "Hold your phone upright";

/// Shows a capture screen under the overlay, following [orientations], and
/// waits for the translations to load.
Future<void> _pump(
  WidgetTester tester,
  Stream<NativeDeviceOrientation> orientations, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
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
          home: HoldUprightOverlay(
            orientations: orientations,
            child: const Text("capture"),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Reports [orientation] and lets the overlay react. Pumps a fixed time, as
/// the prompt's animation repeats and never settles.
Future<void> _turn(
  WidgetTester tester,
  StreamController<NativeDeviceOrientation> sensor,
  NativeDeviceOrientation orientation,
) async {
  sensor.add(orientation);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late StreamController<NativeDeviceOrientation> sensor;

  setUp(() => sensor = StreamController<NativeDeviceOrientation>());
  // Not awaited: close() only completes once a listener got the done event,
  // and not every test hands the controller to the overlay.
  tearDown(() => unawaited(sensor.close()));

  testWidgets("covers the screen while the phone is sideways", (tester) async {
    await _pump(tester, sensor.stream);
    expect(find.text(_prompt), findsNothing);

    await _turn(tester, sensor, NativeDeviceOrientation.landscapeLeft);
    expect(find.text(_prompt), findsOneWidget);

    await _turn(tester, sensor, NativeDeviceOrientation.portraitUp);
    expect(find.text(_prompt), findsNothing);
    expect(find.text("capture"), findsOneWidget);
  });

  testWidgets("covers the screen while the phone is upside down", (
    tester,
  ) async {
    await _pump(tester, sensor.stream);
    await _turn(tester, sensor, NativeDeviceOrientation.portraitDown);
    expect(find.text(_prompt), findsOneWidget);
  });

  for (final (orientation, quarterTurns) in [
    (NativeDeviceOrientation.landscapeLeft, 1),
    (NativeDeviceOrientation.portraitDown, 2),
    (NativeDeviceOrientation.landscapeRight, 3),
  ]) {
    testWidgets("turns the prompt upright in the hand for $orientation", (
      tester,
    ) async {
      await _pump(tester, sensor.stream);
      await _turn(tester, sensor, orientation);
      final prompt = tester.widget<RotatedBox>(
        find.byKey(const Key("hold_upright_prompt")),
      );
      expect(prompt.quarterTurns, quarterTurns);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("keeps the prompt as it was while the phone lies flat", (
    tester,
  ) async {
    await _pump(tester, sensor.stream);
    await _turn(tester, sensor, NativeDeviceOrientation.landscapeRight);
    await _turn(tester, sensor, NativeDeviceOrientation.unknown);
    expect(find.text(_prompt), findsOneWidget);

    await _turn(tester, sensor, NativeDeviceOrientation.portraitUp);
    await _turn(tester, sensor, NativeDeviceOrientation.unknown);
    expect(find.text(_prompt), findsNothing);
  });

  testWidgets("holds the phone still when animations are reduced", (
    tester,
  ) async {
    await _pump(tester, sensor.stream, reduceMotion: true);
    sensor.add(NativeDeviceOrientation.landscapeLeft);
    // Settles only if nothing is animating.
    await tester.pumpAndSettle();
    expect(find.text(_prompt), findsOneWidget);
  });

  testWidgets("shows nothing without a sensor", (tester) async {
    await _pump(tester, Stream.error(UnsupportedError("no sensor")));
    expect(find.text(_prompt), findsNothing);
    expect(find.text("capture"), findsOneWidget);
  });
}
