import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:lottie/lottie.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/enrollment/introduction/widgets/introduction_animation_wrapper.dart";

const _onboardingAssetKey =
    "packages/yivi_core/assets/non-free/onboarding.json";

/// An asset bundle that lets a single test simulate a failing or
/// never-completing load for the onboarding animation, while serving every
/// other asset (fonts, locales, ...) normally.
class _StubbedAssetBundle extends CachingAssetBundle {
  _StubbedAssetBundle({this.failingKey, this.hangingKey});

  final String? failingKey;
  final String? hangingKey;

  @override
  Future<ByteData> load(String key) {
    if (key == failingKey) {
      throw FlutterError("Simulated asset load failure for $key");
    }
    if (key == hangingKey) {
      // Never completes, simulating a load that takes too long.
      return Completer<ByteData>().future;
    }
    return rootBundle.load(key);
  }
}

Widget _wrap(AssetBundle bundle, {required Widget child}) {
  return DefaultAssetBundle(
    bundle: bundle,
    child: MaterialApp(home: IntroductionAnimationWrapper(child: child)),
  );
}

// AnimatedCrossFade keeps both children in the tree throughout the
// transition, so the presence of the content text can't tell us whether the
// intro has actually handed over to it. Its crossFadeState can.
CrossFadeState _crossFadeState(WidgetTester tester) => tester
    .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
    .crossFadeState;

void main() {
  setUp(() {
    // The onboarding animation is cached globally by Lottie, so a failure
    // simulated in one test must not leak into the next.
    Lottie.cache.clear();
  });

  testWidgets("renders the animation at the composition's own frame rate", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(rootBundle, child: const Text("Onboarding content")),
    );
    await tester.pump();

    final lottieBuilder = tester.widget<LottieBuilder>(
      find.byType(LottieBuilder),
    );
    expect(lottieBuilder.frameRate, FrameRate.composition);
  });

  testWidgets("shows the content if the animation fails to load", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _StubbedAssetBundle(failingKey: _onboardingAssetKey),
        child: const Text("Onboarding content"),
      ),
    );
    await tester.pumpAndSettle();

    expect(_crossFadeState(tester), CrossFadeState.showSecond);
  });

  testWidgets("shows the content if the animation takes too long to load", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _StubbedAssetBundle(hangingKey: _onboardingAssetKey),
        child: const Text("Onboarding content"),
      ),
    );
    await tester.pump();

    // The load never resolves, so before the timeout the user is still
    // looking at the (empty) animation placeholder.
    await tester.pump(const Duration(seconds: 9));
    expect(_crossFadeState(tester), CrossFadeState.showFirst);

    // Past the timeout we should skip straight to the content.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(_crossFadeState(tester), CrossFadeState.showSecond);
  });
}
