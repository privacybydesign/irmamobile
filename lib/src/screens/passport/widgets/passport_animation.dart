import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PassportNfcScanningAnimation extends StatefulWidget {
  const PassportNfcScanningAnimation({
    super.key,
    this.forwardDuration = const Duration(seconds: 7),
    this.holdDuration = const Duration(seconds: 1),
  });

  final Duration forwardDuration;
  final Duration holdDuration;

  @override
  State<PassportNfcScanningAnimation> createState() => _PassportNfcScanningAnimationState();
}

class _PassportNfcScanningAnimationState extends State<PassportNfcScanningAnimation> with TickerProviderStateMixin {
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

      //await Future.delayed(widget.holdDuration);
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
