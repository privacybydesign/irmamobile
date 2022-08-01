import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/theme.dart';

class EnrollmentGraphic extends StatelessWidget {
  final String svgImagePath;

  const EnrollmentGraphic(this.svgImagePath);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: IrmaTheme.of(context).surfaceSecondary,
      child: SafeArea(
        child: Center(
          child: SvgPicture.asset(svgImagePath),
        ),
      ),
    );
  }
}
