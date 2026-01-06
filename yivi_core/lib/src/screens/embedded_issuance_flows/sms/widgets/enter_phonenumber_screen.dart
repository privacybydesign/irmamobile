import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";

import "../../../../../package_name.dart";
import "../../../../providers/sms_issuance_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_app_bar.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/translated_text.dart";
import "../../../../widgets/yivi_themed_button.dart";
import "../../../error/error_screen.dart";

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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.addListener(_handleFocusChange);
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
    if (!_focusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // wait for a little bit to be sure the keyboard is fully shown so
      // that the scrollable calculates using the correct view height
      await Future.delayed(const Duration(milliseconds: 200));

      final phoneFieldContext = _phoneFieldPositionKey.currentContext;
      if (phoneFieldContext == null || !phoneFieldContext.mounted) return;

      Scrollable.ensureVisible(
        phoneFieldContext,
        alignment: 0.1,
        duration: Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = ref.watch(smsIssuanceProvider);
    final media = MediaQuery.of(context);
    final onScreenKeyboardShown = media.viewInsets.bottom > 0;

    if (state.error.isNotEmpty) {
      return Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: "sms_issuance.verify_code.title",
        ),
        body: Padding(
          padding: .all(theme.defaultSpacing),
          child: Column(
            mainAxisSize: .max,
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              SizedBox(height: theme.largeSpacing),
              SvgPicture.asset(
                yiviAsset("error/general_error_illustration.svg"),
              ),
              SizedBox(height: theme.largeSpacing),
              TranslatedText(
                "sms_issuance.enter_phone.error",
                textAlign: .center,
              ),
              SizedBox(height: theme.largeSpacing),
              YiviLinkButton(
                textAlign: .center,
                labelTranslationKey: "error.button_show_error",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ErrorScreen(
                        onTapClose: context.pop,
                        type: .general,
                        details: state.error,
                        reportable: false,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: "error.button_retry",
          secondaryButtonLabel: "sms_issuance.enter_phone.back_button",
          onPrimaryPressed: () {
            ref
                .read(smsIssuanceProvider.notifier)
                .sendSms(
                  phoneNumber: state.phoneNumber,
                  language:
                      FlutterI18n.currentLocale(context)?.languageCode ?? "en",
                );
          },
          onSecondaryPressed: context.pop,
        ),
      );
    }

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
          child: SingleChildScrollView(
            key: _scrollableKey,
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

  // Some countries that should appear on the top of the list
  static const preferredOrder = ["NL", "DE", "BE", "GB", "US", "FR"];
}
