import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../models/translated_value.dart';

String getTranslation(BuildContext context, TranslatedValue translations) => translations.translate(
      FlutterI18n.currentLocale(context)!.languageCode,
    );
