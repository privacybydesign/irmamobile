import "package:flutter_test/flutter_test.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_list.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/sms/widgets/enter_phonenumber_screen.dart";

void main() {
  group("SMS excluded countries", () {
    test("excludes Gambia, Montenegro and Mongolia", () {
      expect(excludedSmsCountryCodes, containsAll(["GM", "ME", "MN"]));
    });

    test("keeps commonly used countries selectable", () {
      for (final code in ["NL", "DE", "BE", "GB", "US", "FR"]) {
        expect(excludedSmsCountryCodes, isNot(contains(code)));
      }
    });

    test("the excluded codes exist in the package list and get filtered out", () {
      final available = Countries.countryList
          .map((c) => c["alpha_2_code"])
          .toSet();
      // Guard against a no-op exclusion: the codes must be present to begin with.
      expect(available, containsAll(["GM", "ME", "MN"]));

      final remaining = Countries.countryList
          .where((c) => !excludedSmsCountryCodes.contains(c["alpha_2_code"]))
          .map((c) => c["alpha_2_code"])
          .toSet();
      expect(remaining.intersection({"GM", "ME", "MN"}), isEmpty);
    });
  });
}
