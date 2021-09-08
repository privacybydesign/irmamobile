// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/models/log_entry.dart';

class LogIcon extends StatelessWidget {
  final LogEntryType type;

  const LogIcon(this.type);

  @override
  Widget build(BuildContext context) {
    final iconAssetName = _eventIconAssetName();
    if (iconAssetName == null) {
      return Container();
    }

    return SvgPicture.asset(
      iconAssetName,
      excludeFromSemantics: true,
    );
  }

  String _eventIconAssetName() {
    switch (type) {
      case LogEntryType.removal:
        return "assets/history/removal.svg";
      case LogEntryType.disclosing:
        return "assets/history/disclosing.svg";
      case LogEntryType.issuing:
        return "assets/history/issuing.svg";
      case LogEntryType.signing:
        return "assets/history/signing.svg";
    }
    return null;
  }
}
