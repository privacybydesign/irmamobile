import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";

// Text styles and value formatting shared by the attribute list and by
// attribute group renderers, so a group can match the look of ordinary rows.
// Renderers are free not to use them.

TextStyle attributeLabelStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: theme.neutralExtraDark,
);

TextStyle attributeValueStyle(IrmaThemeData theme, Color color) => TextStyle(
  fontFamily: theme.primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: color,
);

// Small uppercase Open Sans label.
TextStyle attributeEyebrowStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: theme.neutralDark,
  letterSpacing: 0.96, // 0.08em × 12px
);

String formatAttributeBool(BuildContext context, bool? value) {
  if (value == null) return "";
  return FlutterI18n.translate(
    context,
    value ? "credential.boolean_yes" : "credential.boolean_no",
  );
}

/// Formats a string attribute value. A value with a "currency:<code>" display
/// hint is shown as an amount in that currency for the app's locale (e.g.
/// "€ 12,50"); anything else, including values from irmago versions that don't
/// send display hints, is shown as the raw string.
String formatAttributeString(
  BuildContext context,
  schemaless.AttributeValue value,
) {
  final raw = value.string ?? "";
  final hint = value.displayHint;
  if (hint == null || !hint.startsWith(_currencyHintPrefix)) return raw;
  final currency = hint.substring(_currencyHintPrefix.length);
  final locale = FlutterI18n.currentLocale(context)?.toLanguageTag();
  return formatCurrencyAmount(raw, currency, locale) ?? raw;
}

const _currencyHintPrefix = "currency:";
// At most 12 integer digits keep the amount exact in a double, with up to
// three decimals.
final _currencyAmount = RegExp(r"^-?[0-9]{1,12}(\.[0-9]+)?$");
final _currencyCode = RegExp(r"^[A-Z]{3}$");

/// Formats a plain decimal [amount] (e.g. "12.50") in the given ISO 4217
/// [currency] for [locale], or returns null when either can't be formatted
/// or formatting would round or lose digits of the amount.
String? formatCurrencyAmount(String amount, String currency, String? locale) {
  if (!_currencyAmount.hasMatch(amount) || !_currencyCode.hasMatch(currency)) {
    return null;
  }
  try {
    final format = NumberFormat.simpleCurrency(locale: locale, name: currency);
    final fractionDigits = amount.split(".").elementAtOrNull(1)?.length ?? 0;
    if (fractionDigits > (format.decimalDigits ?? 2)) return null;
    return format.format(num.parse(amount));
  } on Object {
    return null;
  }
}

/// Decodes an image attribute value, or returns null when it holds no usable
/// image. Issuers sometimes fill an empty image attribute with a placeholder
/// such as " "; decoding that throws during build and greys out the whole card.
Uint8List? decodeAttributeImage(schemaless.AttributeValue? value) {
  final raw = value?.imagePath ?? value?.base64Image ?? "";
  final Uint8List bytes;
  try {
    bytes = const Base64Decoder().convert(raw.trim());
  } on FormatException {
    return null;
  }
  return bytes.isEmpty ? null : bytes;
}
