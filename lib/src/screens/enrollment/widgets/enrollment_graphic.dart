import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

class EnrollmentGraphic extends StatelessWidget {
  final String imagePath;

  const EnrollmentGraphic(this.imagePath);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Image(
          image: AssetImage(imagePath),
          alignment: Alignment.center,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
