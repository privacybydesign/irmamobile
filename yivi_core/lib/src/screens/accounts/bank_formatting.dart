import "package:flutter/widgets.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";

String? _languageCode(BuildContext context) =>
    FlutterI18n.currentLocale(context)?.languageCode;

/// Formats [amount] in the ISO 4217 [currency] for the app's locale, e.g.
/// "€ 1.843,27". Falls back to the plain number with the currency code.
String formatBankAmount(
  BuildContext context,
  double amount,
  String currency, {
  bool explicitPlus = false,
}) {
  final locale = FlutterI18n.currentLocale(context)?.toLanguageTag();
  String formatted;
  try {
    formatted = NumberFormat.simpleCurrency(
      locale: locale,
      name: currency.isEmpty ? null : currency,
    ).format(amount);
  } on Object {
    formatted = "${amount.toStringAsFixed(2)} $currency".trim();
  }
  return explicitPlus && amount > 0 ? "+$formatted" : formatted;
}

/// A date, e.g. "18 nov 2026".
String formatBankDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(_languageCode(context)).format(date.toLocal());

/// A moment, e.g. "18 nov 09:41".
String formatBankMoment(BuildContext context, DateTime moment) {
  final locale = _languageCode(context);
  final local = moment.toLocal();
  return "${DateFormat.MMMd(locale).format(local)} ${DateFormat.Hm(locale).format(local)}";
}

/// The heading of a day in a list of transactions, e.g. "woensdag 18 november".
String formatBankDay(BuildContext context, DateTime day) =>
    DateFormat.MMMMEEEEd(_languageCode(context)).format(day.toLocal());

/// Groups an IBAN in blocks of four, the way it is printed on bank cards.
String formatAccountNumber(String number) {
  final compact = number.replaceAll(" ", "");
  if (!RegExp(r"^[A-Z]{2}[0-9]{2}[A-Z0-9]+$").hasMatch(compact)) return number;
  return [
    for (var i = 0; i < compact.length; i += 4)
      compact.substring(i, i + 4 > compact.length ? compact.length : i + 4),
  ].join(" ");
}

/// Formats an amount in whole euros, e.g. "€ 3.220".
String formatWholeEuros(BuildContext context, int amount) {
  final locale = FlutterI18n.currentLocale(context)?.toLanguageTag();
  return NumberFormat.simpleCurrency(
    locale: locale,
    name: "EUR",
    decimalDigits: 0,
  ).format(amount);
}
