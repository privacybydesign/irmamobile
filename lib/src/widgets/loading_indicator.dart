import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) => Image.asset(
        "assets/generic/loading_indicator.webp",
        width: size,
        height: size,
      );
}
