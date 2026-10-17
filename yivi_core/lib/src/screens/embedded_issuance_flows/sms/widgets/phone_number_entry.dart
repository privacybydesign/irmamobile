// intl_phone_number_input still takes the core SDK's InputDecoration.
import "package:flutter/material.dart" as core;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_list.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_model.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/translated_text.dart";

/// Alpha-2 codes of countries excluded from the phone number input. Most are
/// excluded because CM (the SMS provider) does not support their phone numbers;
/// Bolivia, Cambodia and Ecuador are excluded because they carry a
/// higher-than-average risk of SMS pumping fraud.
const excludedSmsCountryCodes = {
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
  "MZ", // Mozambique
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

/// The phone number field of adding a phone number: a country picker (the
/// Netherlands first, unsupported countries left out) and the number, filled
/// in with the number typed before (when coming back from the code), and
/// [onValidChanged] whenever it turns valid or invalid. The full screen and
/// the Change sheet both show it.
///
/// [PhoneNumberEntryState.submittable] validates and returns the number to
/// send the code to, or null.
class PhoneNumberEntry extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final ValueChanged<bool> onValidChanged;

  const PhoneNumberEntry({
    super.key,
    required this.focusNode,
    required this.onValidChanged,
  });

  @override
  ConsumerState<PhoneNumberEntry> createState() => PhoneNumberEntryState();
}

class PhoneNumberEntryState extends ConsumerState<PhoneNumberEntry> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  var _currentPhone = PhoneNumber(isoCode: "NL");

  @override
  void initState() {
    super.initState();
    _ensureCaribbeanCountriesRegistered();
    _removeExcludedCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final phone = ref.read(smsIssuanceProvider).phoneNumber;

      // Prefill the phone number box with the phone number for when we're coming back from
      // the code verification page
      if (phone.isNotEmpty) {
        _currentPhone = await PhoneNumber.getRegionInfoFromPhoneNumber(phone);

        // There's a bug in PhoneNumber that doesn't add the + to the dialCode while it should.
        // This is a workaround for that that will also keep working if the bug gets fixed.
        if (!_currentPhone.dialCode!.startsWith("+")) {
          _currentPhone = PhoneNumber(
            phoneNumber: _currentPhone.phoneNumber,
            isoCode: _currentPhone.isoCode,
            dialCode: "+${_currentPhone.dialCode}",
          );
        }

        if (!mounted) return;
        _phoneController.text = _currentPhone.parseNumber();
        widget.onValidChanged(_formKey.currentState!.validate());
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// The number to send the code to, once it is valid.
  String? submittable() =>
      _formKey.currentState!.validate() ? _currentPhone.phoneNumber : null;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final palette = YiviPalette.of(context);
    return Form(
      key: _formKey,
      child: InternationalPhoneNumberInput(
        key: const Key("phone_number_input_field"),
        spaceBetweenSelectorAndTextField: theme.smallSpacing,
        focusNode: widget.focusNode,
        textStyle: palette.body(16),
        selectorTextStyle: palette.body(16, weight: FontWeight.w600),
        inputDecoration: _pillDecoration(
          palette,
          FlutterI18n.translate(context, "sms_issuance.enter_phone.phone_hint"),
        ),
        searchBoxDecoration: core.InputDecoration(
          label: TranslatedText("sms_issuance.enter_phone.search_label"),
          hint: TranslatedText("sms_issuance.enter_phone.search_hint"),
        ),
        initialValue: PhoneNumber(isoCode: _currentPhone.isoCode),
        locale: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
        selectorConfig: SelectorConfig(
          trailingSpace: false,
          setSelectorButtonAsPrefixIcon: true,
          countryComparator: countryComparator,
          selectorType: .BOTTOM_SHEET,
          useBottomSheetSafeArea: true,
        ),
        textFieldController: _phoneController,
        onInputValidated: widget.onValidChanged,
        onInputChanged: (phone) {
          _currentPhone = phone;
        },
        validator: (value) => null,
      ),
    );
  }

  /// The pill look of the other fields for the phone number input, which
  /// takes the core SDK's decoration: the country code sits inside the
  /// outline as its prefix.
  static core.InputDecoration _pillDecoration(
    YiviPalette palette,
    String hint,
  ) {
    core.OutlineInputBorder border(Color color) => core.OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return core.InputDecoration(
      filled: true,
      fillColor: palette.surface,
      hintText: hint,
      hintStyle: palette.body(16).copyWith(color: palette.secondaryText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: border(palette.outline),
      focusedBorder: border(palette.link),
      errorBorder: border(palette.danger),
      focusedErrorBorder: border(palette.danger),
    );
  }

  /// Adds Caribbean countries that are missing from the intl_phone_number_input package.
  static void _ensureCaribbeanCountriesRegistered() {
    final existing = Countries.countryList
        .map((c) => c["alpha_2_code"] as String)
        .toSet();

    const missingCountries = [
      {
        "num_code": "534",
        "alpha_2_code": "SX",
        "alpha_3_code": "SXM",
        "en_short_name": "Sint Maarten",
        "nationality": "Sint Maartener",
        "dial_code": "+1721",
        "nameTranslations": {
          "nl": "Sint Maarten",
          "en": "Sint Maarten",
          "de": "Sint Maarten",
          "fr": "Saint-Martin (partie néerlandaise)",
          "es": "San Martín",
        },
      },
      {
        "num_code": "531",
        "alpha_2_code": "CW",
        "alpha_3_code": "CUW",
        "en_short_name": "Curaçao",
        "nationality": "Curaçaoan",
        "dial_code": "+5999",
        "nameTranslations": {
          "nl": "Curaçao",
          "en": "Curaçao",
          "de": "Curaçao",
          "fr": "Curaçao",
          "es": "Curazao",
        },
      },
      {
        "num_code": "535",
        "alpha_2_code": "BQ",
        "alpha_3_code": "BES",
        "en_short_name": "Caribbean Netherlands",
        "nationality": "Dutch Caribbean",
        "dial_code": "+599",
        "nameTranslations": {
          "nl": "Caribisch Nederland",
          "en": "Caribbean Netherlands",
          "de": "Karibische Niederlande",
          "fr": "Pays-Bas caribéens",
          "es": "Caribe Neerlandés",
        },
      },
    ];

    for (final country in missingCountries) {
      if (!existing.contains(country["alpha_2_code"])) {
        Countries.countryList.add(country);
      }
    }
  }

  int countryComparator(Country a, Country b) {
    // alpha2Code is nullable on Country; a country without one can never be
    // preferred and sorts ahead of the rest.
    final codeA = a.alpha2Code ?? "";
    final codeB = b.alpha2Code ?? "";

    final indexA = preferredOrder.indexOf(codeA);
    final indexB = preferredOrder.indexOf(codeB);

    // If both are preferred countries
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // If only A is preferred
    if (indexA != -1) return -1;

    // If only B is preferred
    if (indexB != -1) return 1;

    // Neither preferred → sort alphabetically.
    return codeA.compareTo(codeB);
  }

  /// Removes countries that should not be available in the phone number input.
  static void _removeExcludedCountries() {
    Countries.countryList.removeWhere(
      (c) => excludedSmsCountryCodes.contains(c["alpha_2_code"]),
    );
  }

  // Some countries that should appear on the top of the list
  static const preferredOrder = ["NL", "DE", "BE", "GB", "US", "FR"];
}
