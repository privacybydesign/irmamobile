import "dart:async";

import "package:lottie/lottie.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../package_name.dart";

class IntroductionAnimationWrapper extends StatefulWidget {
  final Widget child;

  const IntroductionAnimationWrapper({super.key, required this.child});

  @override
  State<IntroductionAnimationWrapper> createState() =>
      _IntroductionAnimationWrapperState();
}

class _IntroductionAnimationWrapperState
    extends State<IntroductionAnimationWrapper>
    with SingleTickerProviderStateMixin {
  // Safety net: if the animation fails to load, or a slow device takes too
  // long to load it, we skip straight to the content instead of leaving the
  // user stuck on the onboarding intro.
  static const _maxWaitDuration = Duration(seconds: 10);

  late final AnimationController _lottieController;
  Timer? _timeoutTimer;
  bool lottieIsCompleted = false;
  bool alignIsCompleted = false;
  bool animationFullyCompleted = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        _skipToContent();
      }
    });
    _timeoutTimer = Timer(_maxWaitDuration, _skipToContent);
  }

  void _skipToContent() {
    _timeoutTimer?.cancel();
    if (mounted && !lottieIsCompleted) {
      setState(() => lottieIsCompleted = true);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const crossFadeDuration = Duration(seconds: 1);
    const alignDuration = Duration(seconds: 1);

    final lottieWidget = Lottie.asset(
      yiviAsset("non-free/onboarding.json"),
      // Render at the composition's own frame rate instead of forcing 60fps,
      // which forces unnecessary interpolation work on slower devices.
      frameRate: FrameRate.composition,
      repeat: false,
      controller: _lottieController,
      onLoaded: (composition) {
        _lottieController.duration = composition.duration;
        _lottieController.forward();
      },
      // If the animation fails to load, skip straight to the content
      // instead of getting stuck.
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _skipToContent());
        return const SizedBox.shrink();
      },
    );

    final aligningLottieWidget = AnimatedAlign(
      duration: alignDuration,
      curve: Curves.fastOutSlowIn,
      alignment: lottieIsCompleted ? Alignment.topCenter : Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: screenSize.height * 0.05),
        child: lottieWidget,
      ),
      onEnd: () {
        setState(() => alignIsCompleted = true);

        // By adding a callback for the duration of the
        // last part of the animation we know when we are fully done
        Future.delayed(crossFadeDuration, () {
          animationFullyCompleted = true;
        });
      },
    );

    return AnimatedCrossFade(
      duration:
          // When the animation is fully done we shorten the duration
          // so that rebuilding (e.g changing device orientation) doesn't
          // animate in a weird way
          animationFullyCompleted
          ? const Duration(milliseconds: 50)
          : crossFadeDuration,
      reverseDuration: const Duration(seconds: 10),
      crossFadeState: alignIsCompleted
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: aligningLottieWidget,
      secondChild: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: widget.child,
      ),
    );
  }
}
