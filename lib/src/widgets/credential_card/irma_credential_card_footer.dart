import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../translated_text.dart';
import 'models/card_expiry_date.dart';

class IrmaCredentialCardFooter extends StatelessWidget {
  final CardExpiryDate expiryDate;

  const IrmaCredentialCardFooter({
    required this.expiryDate,
  });

  String _printableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return TranslatedText(
      'credential.valid_until',
      translationParams: {
        'date': _printableDate(expiryDate.dateTime, lang),
      },
      style: theme.textTheme.caption!.copyWith(
        color: theme.neutral,
      ),
    );
  }
}
