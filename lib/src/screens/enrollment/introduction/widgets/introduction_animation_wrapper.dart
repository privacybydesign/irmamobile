import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class IntroductionAnimationWrapper extends StatefulWidget {
  final Widget child;

  const IntroductionAnimationWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<IntroductionAnimationWrapper> createState() => _IntroductionAnimationWrapperState();
}

class _IntroductionAnimationWrapperState extends State<IntroductionAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  bool lottieIsCompleted = false;
  bool alignIsCompleted = false;
  bool animationFullyCompleted = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() => lottieIsCompleted = true);
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const crossFadeDuration = Duration(seconds: 1);
    const alignDuration = Duration(seconds: 1);

    final lottieWidget = Lottie.asset(
      'assets/non-free/onboarding.json',
      frameRate: FrameRate(60),
      repeat: false,
      controller: _lottieController,
      onLoaded: (composition) {
        _lottieController.duration = composition.duration;
        _lottieController.forward();
      },
    );

    final aligningLottieWidget = AnimatedAlign(
        duration: alignDuration,
        curve: Curves.fastOutSlowIn,
        alignment: lottieIsCompleted ? Alignment.topCenter : Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(top: screenSize.height * 0.075),
          child: lottieWidget,
        ),
        onEnd: () {
          setState(
            () => alignIsCompleted = true,
          );

          // By adding a callback for the duration of the
          // last part of the animation we know when we are fully done
          Future.delayed(crossFadeDuration, () {
            animationFullyCompleted = true;
          });
        });

    return AnimatedCrossFade(
      duration:
          // When the animation is fully done we shorten the duration
          // so that rebuilding (e.g changing device orientation) doesn't
          // animate in a weird way
          animationFullyCompleted ? const Duration(milliseconds: 50) : crossFadeDuration,
      reverseDuration: const Duration(seconds: 10),
      crossFadeState: alignIsCompleted ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: aligningLottieWidget,
      secondChild: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: widget.child,
      ),
    );
  }
}
