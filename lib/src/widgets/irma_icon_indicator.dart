import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IrmaStatusIndicator extends StatelessWidget {
  final bool success;
  final double size;

  const IrmaStatusIndicator({
    required this.success,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Stack(
      children: [
        // Add a white background to the icon to make the check mark or cross more visible
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(5),
            color: Colors.white,
          ),
        ),
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          color: success ? theme.success : theme.error,
          size: size,
        )
      ],
    );
  }
}
