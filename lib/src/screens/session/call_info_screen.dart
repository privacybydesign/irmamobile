import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_quote.dart';
import '../../widgets/translated_text.dart';

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
      translationKey + '_' + (Platform.isAndroid ? 'android' : 'ios');

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return WillPopScope(
      onWillPop: () async {
        onCancel?.call();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'disclosure_permission.call.title',
          leadingAction: () => onCancel?.call(),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'ui.next'),
          onPrimaryPressed: () => onContinue?.call(),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IrmaQuote(
                quote: FlutterI18n.translate(
                  context,
                  'disclosure_permission.call.disclosure_success',
                  translationParams: {
                    'otherParty': otherParty,
                  },
                ),
              ),
              SizedBox(
                height: theme.defaultSpacing,
              ),
              TranslatedText(
                  _appendPlatformToTranslationKey(
                    'disclosure_permission.call.explanation_header',
                  ),
                  style: theme.themeData.textTheme.headlineMedium),
              SizedBox(
                height: theme.tinySpacing,
              ),
              TranslatedText(
                _appendPlatformToTranslationKey(
                  'disclosure_permission.call.explanation',
                ),
                style: theme.themeData.textTheme.bodySmall,
              ),
              // Android requires an extra step
              if (Platform.isAndroid) ...[
                SizedBox(
                  height: theme.mediumSpacing,
                ),
                TranslatedText(
                  'disclosure_permission.call.extra_explanation_header_android',
                  style: theme.themeData.textTheme.headlineMedium,
                ),
                SizedBox(
                  height: theme.tinySpacing,
                ),
                TranslatedText(
                  'disclosure_permission.call.extra_explanation_android',
                  style: theme.themeData.textTheme.bodySmall,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
