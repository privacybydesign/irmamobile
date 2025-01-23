import 'package:flutter/material.dart';

class GreyedOut extends StatelessWidget {
  final Widget child;
  final bool filterActive;

  const GreyedOut({super.key, required this.child, this.filterActive = true});

  @override
  Widget build(BuildContext context) {
    if (!filterActive) return child;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.white.withOpacity(0.5),
        BlendMode.modulate,
      ),
      child: child,
    );
  }
}
