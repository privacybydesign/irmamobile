import "package:flutter/material.dart";
import "package:lottie/lottie.dart";

import "../../../../package_name.dart";
import "../../../util/test_detection.dart";

class PassportNfcScanningAnimation extends StatelessWidget {
  const PassportNfcScanningAnimation({
    super.key,
    this.forwardDuration = const Duration(seconds: 3),
    this.holdDuration = const Duration(seconds: 2),
    this.reverseDuration = const Duration(milliseconds: 1500),
  });

  final Duration forwardDuration;
  final Duration holdDuration;
  final Duration reverseDuration;

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(
      enabled: !isIntegrationTest,
      child: _PassportNfcScanningAnimation(
        forwardDuration: forwardDuration,
        holdDuration: holdDuration,
        reverseDuration: reverseDuration,
      ),
    );
  }
}

class _PassportNfcScanningAnimation extends StatefulWidget {
  const _PassportNfcScanningAnimation({
    required this.forwardDuration,
    required this.holdDuration,
    required this.reverseDuration,
  });

  final Duration forwardDuration;
  final Duration holdDuration;
  final Duration reverseDuration;

  @override
  State<_PassportNfcScanningAnimation> createState() =>
      _PassportNfcScanningAnimationState();
}

class _PassportNfcScanningAnimationState
    extends State<_PassportNfcScanningAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _continue = true;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _playSequence();
  }

  @override
  void dispose() {
    _continue = false;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playSequence() async {
    while (true) {
      if (!_continue) {
        return;
      }
      _controller.value = 0;
      _controller.duration = widget.forwardDuration;
      await _controller.forward();

      await Future.delayed(widget.holdDuration);

      if (!_continue) {
        return;
      }
      _controller.duration = widget.reverseDuration;
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Lottie.asset(
        yiviAsset("passport/nfc.json"),
        controller: _controller,
        alignment: Alignment(0, 0.5),
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return Center(child: CircularProgressIndicator());
          }
          return child;
        },
      ),
    );
  }
}
