import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";

import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/translated_text.dart";

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
  bool _validPhoneNumber = false;
  final _focusNode = FocusNode();

  PhoneNumber _currentPhone = .new(isoCode: "NL");

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text;

      ref.read(smsIssuanceProvider.notifier).sendSms(phoneNumber: phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.enter_phone.title",
        ),
        body: Padding(
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
                    InternationalPhoneNumberInput(
                      spaceBetweenSelectorAndTextField: theme.smallSpacing,
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
                      initialValue: _currentPhone,
                      locale:
                          FlutterI18n.currentLocale(context)?.languageCode ??
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
                      onInputChanged: (phone) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: "sms_issuance.enter_phone.next_button",
          secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
          onPrimaryPressed: _validPhoneNumber ? _submit : null,
          onSecondaryPressed: context.pop,
        ),
      ),
    );
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

  static const preferredOrder = ["NL", "DE", "BE", "GB", "US", "FR"];
}
