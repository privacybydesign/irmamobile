import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../util/test_detection.dart';

class PassportNfcScanningAnimation extends StatelessWidget {
  const PassportNfcScanningAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(enabled: !isIntegrationTest, child: _PassportNfcScanningAnimation());
  }
}

class _PassportNfcScanningAnimation extends StatefulWidget {
  const _PassportNfcScanningAnimation();

  final forwardDuration = const Duration(seconds: 7);
  final holdDuration = const Duration(seconds: 1);

  @override
  State<_PassportNfcScanningAnimation> createState() => _PassportNfcScanningAnimationState();
}

class _PassportNfcScanningAnimationState extends State<_PassportNfcScanningAnimation> with TickerProviderStateMixin {
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
      await _controller.animateTo(7 / 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Lottie.asset(
        'assets/passport/nfc.json',
        alignment: Alignment(0, 0.5),
        controller: _controller,
      ),
    );
  }
}
