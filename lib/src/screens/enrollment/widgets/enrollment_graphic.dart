import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class EnrollmentGraphic extends StatelessWidget {
  final String imagePath;

  const EnrollmentGraphic(
    this.imagePath,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SvgPicture.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}
