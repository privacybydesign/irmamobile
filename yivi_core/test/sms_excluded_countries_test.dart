import "package:flutter_test/flutter_test.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_list.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/sms/widgets/enter_phonenumber_screen.dart";

/// Every country that should be excluded from the SMS phone number picker,
/// because CM (the SMS provider) does not support its phone numbers. Kept as a
/// literal list here so the test fails if a code is accidentally dropped from
/// [excludedSmsCountryCodes].
const _expectedExcludedCodes = {
  "AF", // Afghanistan
  "AO", // Angola
  "DZ", // Algeria
  "AZ", // Azerbaijan
  "BD", // Bangladesh
  "BY", // Belarus
  "BT", // Bhutan
  "BO", // Bolivia (SMS pumping fraud risk)
  "BI", // Burundi
  "KH", // Cambodia (SMS pumping fraud risk)
  "EC", // Ecuador (SMS pumping fraud risk)
  "EG", // Egypt
  "ET", // Ethiopia
  "GM", // Gambia
  "ID", // Indonesia
  "IR", // Iran
  "IQ", // Iraq
  "JO", // Jordan
  "KZ", // Kazakhstan
  "XK", // Kosovo
  "KG", // Kyrgyzstan
  "LB", // Lebanon
  "LY", // Libya
  "MG", // Madagascar
  "MW", // Malawi
  "MR", // Mauritania
  "MN", // Mongolia
  "ME", // Montenegro
  "NP", // Nepal
  "PK", // Pakistan
  "RU", // Russia
  "SN", // Senegal
  "SI", // Slovenia
  "LK", // Sri Lanka
  "SY", // Syria
  "TJ", // Tajikistan
  "TZ", // Tanzania
  "TN", // Tunisia
  "TM", // Turkmenistan
  "UZ", // Uzbekistan
  "YE", // Yemen
};

void main() {
  group("SMS excluded countries", () {
    test("excludes every unsupported country", () {
      expect(excludedSmsCountryCodes, equals(_expectedExcludedCodes));
    });

    test("keeps commonly used countries selectable", () {
      for (final code in ["NL", "DE", "BE", "GB", "US", "FR"]) {
        expect(excludedSmsCountryCodes, isNot(contains(code)));
      }
    });

    test(
      "every excluded code exists in the package list and gets filtered out",
      () {
        final available = Countries.countryList
            .map((c) => c["alpha_2_code"])
            .toSet();
        // Guard against a no-op exclusion: each code must be present to begin with.
        expect(available, containsAll(excludedSmsCountryCodes));

        final remaining = Countries.countryList
            .where((c) => !excludedSmsCountryCodes.contains(c["alpha_2_code"]))
            .map((c) => c["alpha_2_code"])
            .toSet();
        expect(remaining.intersection(excludedSmsCountryCodes), isEmpty);
      },
    );
  });
}
