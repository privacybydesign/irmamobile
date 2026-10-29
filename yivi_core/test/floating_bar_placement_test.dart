import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/glass/floating_bar_placement.dart";

/// Measures [FloatingBarPlacement] on [platform] with the given insets.
Future<T> _measure<T>(
  WidgetTester tester, {
  required TargetPlatform platform,
  required EdgeInsets viewPadding,
  EdgeInsets gestures = EdgeInsets.zero,
  required T Function(BuildContext context) read,
}) async {
  late T value;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        viewPadding: viewPadding,
        padding: viewPadding,
        systemGestureInsets: gestures,
      ),
      child: Theme(
        data: ThemeData(platform: platform),
        child: Builder(
          builder: (context) {
            value = read(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return value;
}

void main() {
  // Measured on an Android 16 emulator (Medium Phone).
  const buttonsInset = EdgeInsets.only(top: 24, bottom: 48);
  const gestureInset = EdgeInsets.only(top: 24, bottom: 24);
  const gestureSides = EdgeInsets.only(left: 29.7, right: 29.7, bottom: 32);

  testWidgets("Android with buttons: clear of them", (tester) async {
    Future<double> read(double Function(BuildContext) f) => _measure(
      tester,
      platform: TargetPlatform.android,
      viewPadding: buttonsInset,
      read: f,
    );
    expect(
      await read((c) => FloatingBarPlacement.buttonNavigation(c) ? 1 : 0),
      1,
    );
    expect(await read(FloatingBarPlacement.buttonBottom), 64);
    expect(
      await read((c) => FloatingBarPlacement.buttonBottom(c, text: true)),
      56,
    );
    expect(await read(FloatingBarPlacement.tabBarBottom), 60);
  });

  testWidgets("Android with gestures: as before", (tester) async {
    Future<double> read(double Function(BuildContext) f) => _measure(
      tester,
      platform: TargetPlatform.android,
      viewPadding: gestureInset,
      gestures: gestureSides,
      read: f,
    );
    expect(
      await read((c) => FloatingBarPlacement.buttonNavigation(c) ? 1 : 0),
      0,
    );
    expect(await read(FloatingBarPlacement.buttonBottom), 29);
    expect(
      await read((c) => FloatingBarPlacement.buttonBottom(c, text: true)),
      24,
    );
    expect(await read(FloatingBarPlacement.tabBarBottom), 32);
  });

  testWidgets("iOS never counts as button navigation", (tester) async {
    final buttons = await _measure(
      tester,
      platform: TargetPlatform.iOS,
      viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
      read: FloatingBarPlacement.buttonNavigation,
    );
    expect(buttons, isFalse);
  });
}
