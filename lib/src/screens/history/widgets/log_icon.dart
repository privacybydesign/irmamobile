import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'log.dart';

class LogIcon extends StatelessWidget {
  final LogType type;

  const LogIcon(this.type);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(_eventIconAssetName());
  }

  String _eventIconAssetName() {
    switch (type) {
      case LogType.removal:
        return "assets/history/removal.svg";
      case LogType.disclosing:
        return "assets/history/disclosing.svg";
      case LogType.issuing:
        return "assets/history/issuing.svg";
      case LogType.signing:
        return "assets/history/signing.svg";
    }
    return "";
  }
}
