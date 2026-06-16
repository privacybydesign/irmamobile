import "dart:io" show Platform;

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_quote.dart";
import "../../widgets/translated_text.dart";

class CallInfoScreen extends StatelessWidget {
  final String otherParty;
  final Function()? onContinue;
  final Function()? onCancel;

  const CallInfoScreen({
    required this.otherParty,
    this.onContinue,
    this.onCancel,
  });

  String _appendPlatformToTranslationKey(String translationKey) =>
      '${translationKey}_${Platform.isAndroid ? 'android' : 'ios'}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) {
        onCancel?.call();
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: "disclosure_permission.call.title",
          leading: YiviBackButton(onTap: () => onCancel?.call()),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, "ui.next"),
          onPrimaryPressed: () => onContinue?.call(),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(context.yivi.spacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IrmaQuote(
                quote: FlutterI18n.translate(
                  context,
                  "disclosure_permission.call.disclosure_success",
                  translationParams: {"otherParty": otherParty},
                ),
              ),
              SizedBox(height: context.yivi.spacing.base),
              TranslatedText(
                _appendPlatformToTranslationKey(
                  "disclosure_permission.call.explanation_header",
                ),
                style: context.text.headlineMedium,
              ),
              SizedBox(height: context.yivi.spacing.tiny),
              TranslatedText(
                _appendPlatformToTranslationKey(
                  "disclosure_permission.call.explanation",
                ),
                style: context.text.bodySmall,
              ),
              // Android requires an extra step
              if (Platform.isAndroid) ...[
                SizedBox(height: context.yivi.spacing.medium),
                TranslatedText(
                  "disclosure_permission.call.extra_explanation_header_android",
                  style: context.text.headlineMedium,
                ),
                SizedBox(height: context.yivi.spacing.tiny),
                TranslatedText(
                  "disclosure_permission.call.extra_explanation_android",
                  style: context.text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
