import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";
// The package's field opens its own bottom sheet for the country, which
// cannot be changed; its data, validation and formatting are used here
// under the app's own field and sheet.
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_list.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/models/country_model.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/providers/country_provider.dart";
// ignore: implementation_imports
import "package:intl_phone_number_input/src/utils/phone_number/phone_number_util.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/glass/glass_surface.dart";
import "../../../../widgets/pill_text_field.dart";
import "country_picker_sheet.dart";

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

/// The phone number field of adding a phone number: one pill like the other
/// fields, with the country (its flag and dialling code) at its start. A tap
/// on the country opens a sheet to pick another (the Netherlands and its
/// neighbours first, unsupported countries left out). The number is
/// formatted as it is typed, filled in with the number typed before (when
/// coming back from the code), and [onValidChanged] follows whether it is a
/// valid number. The full screen and the Change sheet both show it.
///
/// [PhoneNumberEntryState.submittable] returns the number to send the code
/// to (international format), or null while it is not valid.
class PhoneNumberEntry extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final ValueChanged<bool> onValidChanged;

  /// The keyboard's return key ("Next"): the step's way on. The phone pad
  /// has none on iOS; elsewhere it does.
  final VoidCallback? onSubmitted;

  const PhoneNumberEntry({
    super.key,
    required this.focusNode,
    required this.onValidChanged,
    this.onSubmitted,
  });

  @override
  ConsumerState<PhoneNumberEntry> createState() => PhoneNumberEntryState();
}

class PhoneNumberEntryState extends ConsumerState<PhoneNumberEntry> {
  final _controller = TextEditingController();

  late final List<Country> _countries;
  late Country _country;

  /// The number in international format, while it is valid.
  String? _valid;

  /// Which check of the typed number is the latest (they are async).
  var _check = 0;

  @override
  void initState() {
    super.initState();
    _ensureCaribbeanCountriesRegistered();
    _removeExcludedCountries();
    _countries = CountryProvider.getCountriesData(
      countries: null,
    ).where((c) => c.alpha2Code != null).toSet().toList();
    _country = _countryOf("NL") ?? _countries.first;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The number typed before, when coming back from the code.
      final phone = ref.read(smsIssuanceProvider).phoneNumber;
      if (phone.isEmpty) return;
      final known = await PhoneNumber.getRegionInfoFromPhoneNumber(phone);
      if (!mounted) return;
      final country = _countryOf(known.isoCode);
      if (country == null) return;
      final dial = country.dialCode ?? "";
      setState(() => _country = country);
      _controller.text = phone.startsWith(dial)
          ? phone.substring(dial.length)
          : known.parseNumber();
      _changed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Country? _countryOf(String? isoCode) =>
      _countries.where((c) => c.alpha2Code == isoCode).firstOrNull;

  /// The number to send the code to, once it is valid.
  String? submittable() => _valid;

  void _setValid(String? number) {
    final was = _valid != null;
    _valid = number;
    if (was != (number != null)) widget.onValidChanged(number != null);
  }

  Future<void> _validate() async {
    final check = ++_check;
    final digits = _controller.text.replaceAll(RegExp(r"[^\d+]"), "");
    final iso = _country.alpha2Code!;
    String? number;
    try {
      if (digits.isNotEmpty &&
          (await PhoneNumberUtil.isValidNumber(
                phoneNumber: digits,
                isoCode: iso,
              ) ??
              false)) {
        number = await PhoneNumberUtil.normalizePhoneNumber(
          phoneNumber: digits,
          isoCode: iso,
        );
      }
    } on Exception {
      number = null;
    }
    if (!mounted || check != _check) return;
    _setValid(number);
  }

  /// Groups the number the way the country writes it ("06 12345678"), as
  /// it is typed at its end, and checks it.
  Future<void> _changed() async {
    _validate();
    final value = _controller.value;
    final digits = value.text.replaceAll(RegExp(r"[^\d+]"), "");
    if (digits.isEmpty || value.selection.end != value.text.length) return;
    String? formatted;
    try {
      formatted = await PhoneNumberUtil.formatAsYouType(
        phoneNumber: digits,
        isoCode: _country.alpha2Code!,
      );
    } on Exception {
      return;
    }
    // Only while nothing was typed meanwhile.
    if (!mounted || formatted == null || _controller.value != value) return;
    if (formatted.replaceAll(RegExp(r"[^\d+]"), "") != digits) return;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _pickCountry() async {
    widget.focusNode.unfocus();
    final picked = await showCountryPickerSheet(
      context: context,
      countries: _countries,
      selected: _country,
      common: preferredOrder,
    );
    if (!mounted) return;
    if (picked != null && picked.alpha2Code != _country.alpha2Code) {
      setState(() => _country = picked);
      _changed();
    }
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final language = FlutterI18n.currentLocale(context)?.languageCode;
    return TextField(
      key: const Key("phone_number_input_field"),
      controller: _controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.phone,
      textInputAction: widget.onSubmitted == null ? null : .next,
      onSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textDirection: TextDirection.ltr,
      style: palette
          .body(17, weight: FontWeight.w600)
          .copyWith(color: palette.text, letterSpacing: 0.4),
      cursorColor: palette.link,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[\d+ ]")),
        LengthLimitingTextInputFormatter(20),
      ],
      onChanged: (_) => _changed(),
      decoration:
          pillInputDecoration(
            context,
            hint: FlutterI18n.translate(
              context,
              "sms_issuance.enter_phone.phone_hint",
            ),
          ).copyWith(
            contentPadding: const EdgeInsets.fromLTRB(4, 17, 20, 17),
            prefixIcon: _CountryButton(
              country: _country,
              label: FlutterI18n.translate(
                context,
                "sms_issuance.enter_phone.country_button",
                translationParams: {
                  "country": countryName(_country, language),
                  "code": _country.dialCode ?? "",
                },
              ),
              onTap: _pickCountry,
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 56),
          ),
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

  /// Removes countries that should not be available in the phone number input.
  static void _removeExcludedCountries() {
    Countries.countryList.removeWhere(
      (c) => excludedSmsCountryCodes.contains(c["alpha_2_code"]),
    );
  }

  /// The countries at the top of the picker, under "Common".
  static const preferredOrder = ["NL", "DE", "BE", "GB", "US", "FR"];
}

/// The country at the start of the phone number field: its flag and
/// dialling code, a chevron, and a line between it and the number. A tap
/// opens the country picker.
class _CountryButton extends StatelessWidget {
  final Country country;
  final String label;
  final VoidCallback onTap;

  const _CountryButton({
    required this.country,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: PressScale(
        scale: PressScale.button,
        child: GestureDetector(
          key: const Key("phone_country_button"),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountryFlag(country: country, width: 26),
                const SizedBox(width: 8),
                Text(
                  country.dialCode ?? "",
                  textDirection: TextDirection.ltr,
                  style: palette
                      .body(17, weight: FontWeight.w600)
                      .copyWith(color: palette.text),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: palette.secondaryText,
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 26, color: palette.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
