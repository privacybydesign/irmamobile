import 'package:flutter/material.dart';

class GreyedOut extends StatelessWidget {
  final Widget child;
  final bool filterActive;

  const GreyedOut({super.key, required this.child, this.filterActive = true});

  @override
  Widget build(BuildContext context) {
    if (!filterActive) return child;

    return ColorFiltered(colorFilter: ColorFilter.mode(Colors.white.withAlpha(128), BlendMode.modulate), child: child);
  }
}
