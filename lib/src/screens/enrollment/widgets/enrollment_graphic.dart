import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import '../../../theme/theme.dart';

class EnrollmentGraphic extends StatelessWidget {
  final String imagePath;

  const EnrollmentGraphic(
    this.imagePath,
  );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      minimum: isLandscape
          ? EdgeInsets.symmetric(
              vertical: theme.defaultSpacing,
            )
          : EdgeInsets.zero,
      child: SvgPicture.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}
