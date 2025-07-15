import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../../../theme/theme.dart';

class EnrollmentHero extends StatelessWidget {
  final String imagePath;

  EnrollmentHero(this.imagePath) : assert(imagePath.endsWith('svg') || imagePath.endsWith('json'));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      minimum: isLandscape ? EdgeInsets.symmetric(vertical: theme.defaultSpacing) : EdgeInsets.zero,
      child: imagePath.endsWith('json')
          ? Lottie.asset(imagePath, frameRate: FrameRate(60))
          : SvgPicture.asset(imagePath, fit: BoxFit.contain),
    );
  }
}
