import "package:camera/camera.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/mrz_camera_feed.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/mrz_scanner.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

/// A camera that only counts: whether it runs, and how often it was
/// started and released.
class _FakeFeed implements MrzCameraFeed {
  var starts = 0;
  var stops = 0;
  @override
  var running = false;

  @override
  Widget? preview() => running ? const SizedBox.expand() : null;

  @override
  double get aspectRatio => 16 / 9;

  @override
  int? imageRotation() => 0;

  @override
  Future<void> start(void Function(CameraImage image) onImage) async {
    if (running) return;
    starts++;
    running = true;
  }

  @override
  Future<void> stop() async {
    if (!running) return;
    stops++;
    running = false;
  }
}

void main() {
  late _FakeFeed feed;
  late GlobalKey<NavigatorState> navigator;
  late ValueNotifier<bool> tickers;
  late ValueNotifier<bool> shown;

  setUp(() {
    feed = _FakeFeed();
    navigator = GlobalKey<NavigatorState>();
    tickers = ValueNotifier(true);
    shown = ValueNotifier(true);
  });

  Future<void> pump(WidgetTester tester) async {
    final overrides = <Override>[
      mrzCameraFeedProvider.overrideWithValue(() => feed),
    ];
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: overrides,
        child: IrmaTheme(
          builder: (_) => MaterialApp(
            navigatorKey: navigator,
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: TestTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: const Locale("en", "US"),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: ValueListenableBuilder<bool>(
              valueListenable: shown,
              builder: (_, isShown, _) => isShown
                  ? ValueListenableBuilder<bool>(
                      valueListenable: tickers,
                      builder: (_, on, _) => TickerMode(
                        enabled: on,
                        child: MrzScanner(
                          onSuccess: (_) {},
                          mrzParser: PassportMrzParser(),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets("runs while on screen", (tester) async {
    await pump(tester);
    expect(feed.running, isTrue);
    expect(feed.starts, 1);
  });

  testWidgets("a route over it stops the camera; back on it, it starts", (
    tester,
  ) async {
    await pump(tester);
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text("chip")),
    );
    await tester.pumpAndSettle();
    expect(feed.running, isFalse);
    expect(feed.stops, 1);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(feed.running, isTrue);
    expect(feed.starts, 2);
  });

  testWidgets("a page under another (tickers off) stops the camera", (
    tester,
  ) async {
    await pump(tester);
    tickers.value = false;
    await tester.pump();
    expect(feed.running, isFalse);
    tickers.value = true;
    await tester.pump();
    expect(feed.running, isTrue);
  });

  testWidgets("the app in the background stops the camera", (tester) async {
    await pump(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(feed.running, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(feed.running, isTrue);
  });

  testWidgets("gone from the screen: the camera is released", (tester) async {
    await pump(tester);
    shown.value = false;
    await tester.pump();
    expect(feed.running, isFalse);
    expect(feed.stops, 1);
  });
}
