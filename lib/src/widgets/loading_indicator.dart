import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Image.asset(
        "assets/generic/loading_indicator.webp",
        width: 120,
        height: 120,
      );
}
