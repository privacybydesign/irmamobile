import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Subtitle extends StatelessWidget {
  final LogEntryType logType;

  const Subtitle(this.logType);

  @override
  Widget build(BuildContext context) {
    return Text(
      _text(context),
      style: IrmaTheme.of(context).textTheme.display2,
    );
  }

  String _text(BuildContext context) {
    switch (logType) {
      case LogEntryType.removal:
        return FlutterI18n.translate(context, "history.type.removal.subtitle");
      case LogEntryType.disclosing:
        return FlutterI18n.translate(context, "history.type.disclosing.subtitle");
      case LogEntryType.issuing:
        return FlutterI18n.translate(context, "history.type.issuing.subtitle");
      case LogEntryType.signing:
        return FlutterI18n.translate(context, "history.type.signing.subtitle");
    }
    return "";
  }
}
