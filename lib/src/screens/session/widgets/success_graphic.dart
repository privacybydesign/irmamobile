import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SuccessGraphic extends StatefulWidget {
  @override
  State<SuccessGraphic> createState() => _SuccessGraphicState();
}

class _SuccessGraphicState extends State<SuccessGraphic> {
  final int randomImageIndex = Random().nextInt(5) + 1;

  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/success/success_$randomImageIndex.svg');
}
