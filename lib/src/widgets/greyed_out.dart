import 'package:flutter/material.dart';

class GreyedOut extends StatelessWidget {
  final Widget child;
  final bool filterActive;

  const GreyedOut({Key? key, required this.child, this.filterActive = true}) : super(key: key);

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
