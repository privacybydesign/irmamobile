import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../providers/resend_wait.dart";

/// A button that sends a code again, while it has to wait ([until], see
/// [ResendWait]): [builder] gets the time left, "0:42", and builds the
/// button dimmed and without an action; at 0:00 it gets null and builds the
/// normal button. Counts down every second.
class ResendCountdown extends ConsumerStatefulWidget {
  final DateTime? until;
  final Widget Function(BuildContext context, String? left) builder;

  const ResendCountdown({
    super.key,
    required this.until,
    required this.builder,
  });

  /// [left] as minutes and seconds, the seconds rounded up: "0:42", "1:00".
  static String format(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    return "${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, "0")}";
  }

  @override
  ConsumerState<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends ConsumerState<ResendCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendCountdown old) {
    super.didUpdateWidget(old);
    if (old.until != widget.until) _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Duration? get _left {
    final until = widget.until;
    if (until == null) return null;
    final left = until.difference(ref.read(resendClockProvider)());
    return left > Duration.zero ? left : null;
  }

  void _start() {
    _tick?.cancel();
    if (_left == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == null) _tick?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    return widget.builder(
      context,
      left == null ? null : ResendCountdown.format(left),
    );
  }
}
