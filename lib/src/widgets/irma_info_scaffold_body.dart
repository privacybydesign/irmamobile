import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'irma_button.dart';
import 'irma_dialog.dart';
import 'irma_themed_button.dart';
import 'translated_text.dart';

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String titleKey;
  final Map<String, String>? titleParams;
  final String? bodyKey;
  final Map<String, String>? bodyParams;
  final IconData? icon;
  final Color? iconColor;
  final String? linkKey;
  final String? linkDialogText;

  const IrmaInfoScaffoldBody({
    Key? key,
    required this.titleKey,
    this.titleParams,
    this.bodyParams,
    required this.bodyKey,
    this.icon,
    this.iconColor,
    this.linkDialogText,
    this.linkKey,
  })  : assert(
          iconColor == null || icon != null,
          'Icon color can only be used when an icon is provided',
        ),
        assert(
          linkKey != null || linkDialogText == null,
          'If you specify a linkKey, also set a linkDialogKey',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    Future _showIrmaDialog() async => showDialog(
          context: context,
          builder: (context) {
            return IrmaDialog(
              title: FlutterI18n.translate(context, 'error.details_title'),
              content: linkDialogText!,
              child: IrmaButton(
                size: IrmaButtonSize.small,
                onPressed: () => Navigator.of(context).pop(),
                label: 'error.button_ok',
              ),
            );
          },
        );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? theme.themeData.colorScheme.primary,
                size: 125,
              ),
              SizedBox(height: theme.mediumSpacing),
            ],
            TranslatedText(
              titleKey,
              translationParams: titleParams,
              style: theme.textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            if (bodyKey != null) ...[
              SizedBox(height: theme.mediumSpacing),
              TranslatedText(
                bodyKey!,
                translationParams: bodyParams,
                style: theme.textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ],
            if (linkKey != null) ...[
              SizedBox(height: theme.mediumSpacing),
              GestureDetector(
                onTap: _showIrmaDialog,
                child: TranslatedText(
                  linkKey!,
                  style: theme.textTheme.bodyText2?.copyWith(
                    decoration: TextDecoration.underline,
                    color: theme.linkColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
