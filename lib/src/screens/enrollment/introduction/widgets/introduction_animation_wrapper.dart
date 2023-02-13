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
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      alignment: lottieIsCompleted ? Alignment.topCenter : Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: screenSize.height * 0.075),
        child: lottieWidget,
      ),
      onEnd: () => setState(
        () => alignIsCompleted = true,
      ),
    );

    return AnimatedCrossFade(
      duration: const Duration(seconds: 1),
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
