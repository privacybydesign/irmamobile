import "dart:math";

import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";

class SuccessGraphic extends StatefulWidget {
  const SuccessGraphic({super.key});

  @override
  State<SuccessGraphic> createState() => _SuccessGraphicState();
}

class _SuccessGraphicState extends State<SuccessGraphic> {
  final int randomImageIndex = Random().nextInt(5) + 1;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(yiviAsset("success/success_$randomImageIndex.svg"));
}
