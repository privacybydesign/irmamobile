import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";
import "package:intl_phone_number_input/src/models/country_list.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/keyboard_animation_listener.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../widgets/embedded_issuance_error_screen.dart";

class EnterPhoneScreen extends ConsumerStatefulWidget {
  const EnterPhoneScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EnterPhoneScreenState();
  }
}

class _EnterPhoneScreenState extends ConsumerState<EnterPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _phoneFieldPositionKey = GlobalKey();

  // key used to maintain the scrollable's state when the scaffold key updates
  // and thus voids its own state
  final _scrollableKey = GlobalKey();

  var _currentPhone = PhoneNumber(isoCode: "NL");
  var _validPhoneNumber = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ensureCaribbeanCountriesRegistered();
    _removeExcludedCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.addListener(_handleFocusChange);
      _focusNode.requestFocus();

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

        _phoneController.text = _currentPhone.parseNumber();
        setState(() {
          _validPhoneNumber = _formKey.currentState!.validate();
        });
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final phone = _currentPhone.phoneNumber;
      if (phone == null) {
        return;
      }

      ref
          .read(smsIssuanceProvider.notifier)
          .sendSms(
            phoneNumber: phone,
            language: FlutterI18n.currentLocale(context)?.languageCode ?? "en",
          );
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final phoneFieldContext = _phoneFieldPositionKey.currentContext;
        if (phoneFieldContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          phoneFieldContext,
          alignment: 0.1,
          duration: Duration(milliseconds: 300),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsIssuanceProvider);

    if (state.error is! SmsIssuanceNoError) {
      return EmbeddedIssuanceErrorScreen(
        titleTranslationKey: "sms_issuance.verify_code.title",
        contentTranslationKey: "sms_issuance.enter_phone.error",
        errorMessage: state.error.toString(),
        onTryAgain: () {
          ref
              .read(smsIssuanceProvider.notifier)
              .sendSms(
                phoneNumber: state.phoneNumber,
                language:
                    FlutterI18n.currentLocale(context)?.languageCode ?? "en",
              );
        },
      );
    }

    final theme = IrmaTheme.of(context);
    final media = MediaQuery.of(context);
    final onScreenKeyboardShown = media.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        key: Key("$onScreenKeyboardShown"),
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.enter_phone.title",
        ),
        body: SafeArea(
          child: KeyboardAnimationListener(
            key: _scrollableKey,
            onKeyboardSettled: (context, inset, visible) {
              _handleFocusChange();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText(
                      "sms_issuance.enter_phone.header",
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(height: theme.defaultSpacing),
                    TranslatedText("sms_issuance.enter_phone.body"),
                    SizedBox(height: theme.largeSpacing),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          Container(
                            key: _phoneFieldPositionKey,
                            child: InternationalPhoneNumberInput(
                              key: const Key("phone_number_input_field"),
                              spaceBetweenSelectorAndTextField:
                                  theme.smallSpacing,
                              focusNode: _focusNode,
                              inputDecoration: InputDecoration(
                                hint: TranslatedText(
                                  "sms_issuance.enter_phone.phone_hint",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              searchBoxDecoration: InputDecoration(
                                label: TranslatedText(
                                  "sms_issuance.enter_phone.search_label",
                                ),
                                hint: TranslatedText(
                                  "sms_issuance.enter_phone.search_hint",
                                ),
                              ),
                              initialValue: PhoneNumber(
                                isoCode: _currentPhone.isoCode,
                              ),
                              locale:
                                  FlutterI18n.currentLocale(
                                    context,
                                  )?.languageCode ??
                                  "en",
                              selectorConfig: SelectorConfig(
                                trailingSpace: false,
                                setSelectorButtonAsPrefixIcon: true,
                                countryComparator: countryComparator,
                                selectorType: .BOTTOM_SHEET,
                                useBottomSheetSafeArea: true,
                              ),
                              textFieldController: _phoneController,
                              onInputValidated: (valid) {
                                setState(() => _validPhoneNumber = valid);
                              },
                              onInputChanged: (phone) {
                                _currentPhone = phone;
                              },
                              validator: (value) => null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),

        // When the on-screen keyboard is shown we want to show the "send sms" button above it
        // without the cancel button. When the keyboard is not showing we want to show both the send
        // and cancel button.
        floatingActionButtonAnimator: .noAnimation,
        floatingActionButton: onScreenKeyboardShown
            ? Padding(
                padding: .only(
                  left: theme.defaultSpacing + media.padding.left,
                  right: theme.defaultSpacing + media.padding.right,
                ),
                child: YiviThemedButton(
                  label: "sms_issuance.enter_phone.next_button",
                  onPressed: _validPhoneNumber ? _submit : null,
                ),
              )
            : null,
        floatingActionButtonLocation: .centerFloat,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: onScreenKeyboardShown
            ? null
            : IrmaBottomBar(
                primaryButtonLabel: "sms_issuance.enter_phone.next_button",
                secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
                onPrimaryPressed: _validPhoneNumber ? _submit : null,
                onSecondaryPressed: context.pop,
              ),
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

  int countryComparator(a, b) {
    final indexA = preferredOrder.indexOf(a.alpha2Code);
    final indexB = preferredOrder.indexOf(b.alpha2Code);

    // If both are preferred countries
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // If only A is preferred
    if (indexA != -1) return -1;

    // If only B is preferred
    if (indexB != -1) return 1;

    // Neither preferred → keep original ordering or sort alphabetically
    return a.alpha2Code.compareTo(b.alpha2Code);
  }

  /// Removes countries that should not be available in the phone number input.
  static void _removeExcludedCountries() {
    const excludedCountries = {
      "AF", // Afghanistan
      "AO", // Angola
      "DZ", // Algeria
      "AZ", // Azerbaijan
      "BD", // Bangladesh
      "BY", // Belarus
      "BT", // Bhutan
      "BI", // Burundi
      "EG", // Egypt
      "ET", // Ethiopia
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

    Countries.countryList.removeWhere(
      (c) => excludedCountries.contains(c["alpha_2_code"]),
    );
  }

  // Some countries that should appear on the top of the list
  static const preferredOrder = ["NL", "DE", "BE", "GB", "US", "FR"];
}
