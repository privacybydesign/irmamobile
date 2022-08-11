import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/theme.dart';
import 'irma_button.dart';
import 'irma_dialog.dart';
import 'irma_themed_button.dart';
import 'translated_text.dart';

class IrmaInfoScaffoldBody extends StatelessWidget {
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String? bodyTranslationKey;
  final Map<String, String>? bodyTranslationParams;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;
  final String? linkTranslationKey;
  final String? linkDialogText;

  const IrmaInfoScaffoldBody({
    Key? key,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    this.bodyTranslationParams,
    required this.bodyTranslationKey,
    this.imagePath,
    this.icon,
    this.iconColor,
    this.linkDialogText,
    this.linkTranslationKey,
  })  : assert(
          iconColor == null || icon != null,
          'Icon color can only be used when an icon is provided',
        ),
        assert(
          linkTranslationKey != null || linkDialogText == null,
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
            if (icon != null || imagePath != null) ...[
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ?? theme.themeData.colorScheme.secondary,
                  size: 125,
                ),
              if (imagePath != null) SvgPicture.asset(imagePath!),
              SizedBox(height: theme.mediumSpacing),
            ],
            TranslatedText(
              titleTranslationKey,
              translationParams: titleTranslationParams,
              style: theme.textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            if (bodyTranslationKey != null) ...[
              SizedBox(height: theme.mediumSpacing),
              TranslatedText(
                bodyTranslationKey!,
                translationParams: bodyTranslationParams,
                style: theme.textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ],
            if (linkTranslationKey != null) ...[
              SizedBox(height: theme.mediumSpacing),
              GestureDetector(
                onTap: _showIrmaDialog,
                child: TranslatedText(
                  linkTranslationKey!,
                  style: theme.textTheme.bodyText2?.copyWith(
                    decoration: TextDecoration.underline,
                    color: theme.link,
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
