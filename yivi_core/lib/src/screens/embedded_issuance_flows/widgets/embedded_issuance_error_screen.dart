import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";

class EmbeddedIssuanceErrorScreen extends StatelessWidget {
  const EmbeddedIssuanceErrorScreen({
    super.key,
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    required this.errorMessage,
    required this.onTryAgain,
  });

  final String titleTranslationKey;
  final String contentTranslationKey;
  final String errorMessage;
  final Function() onTryAgain;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(titleTranslationKey: titleTranslationKey),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: .all(theme.defaultSpacing),
            child: SizedBox(
              width: .infinity,
              child: Builder(
                builder: (context) {
                  final orientation = MediaQuery.of(context).orientation;

                  if (orientation == .landscape) {
                    return Row(
                      mainAxisSize: .max,
                      mainAxisAlignment: .center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              TranslatedText(
                                "email_issuance.enter_email.error",
                                textAlign: .start,
                              ),
                              SizedBox(height: theme.largeSpacing),
                              YiviLinkButton(
                                textAlign: .start,
                                labelTranslationKey: "error.button_show_error",
                                onTap: () {
                                  _showIrmaDialog(context, errorMessage);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: theme.largeSpacing),
                        Flexible(
                          child: SvgPicture.asset(
                            height: 200,
                            yiviAsset("error/general_error_illustration.svg"),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
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
                        "email_issuance.enter_email.error",
                        textAlign: .center,
                      ),
                      SizedBox(height: theme.largeSpacing),
                      YiviLinkButton(
                        textAlign: .center,
                        labelTranslationKey: "error.button_show_error",
                        onTap: () {
                          _showIrmaDialog(context, errorMessage);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "error.button_retry",
        secondaryButtonLabel: "email_issuance.enter_email.back_button",
        onPrimaryPressed: onTryAgain,
        onSecondaryPressed: context.pop,
      ),
    );
  }

  Future _showIrmaDialog(BuildContext context, String content) async {
    await showDialog(
      context: context,
      builder: (context) {
        return IrmaDialog(
          title: FlutterI18n.translate(context, "error.details_title"),
          content: content,
          child: YiviThemedButton(
            label: "error.button_ok",
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}
