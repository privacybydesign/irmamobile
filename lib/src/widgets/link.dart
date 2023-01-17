import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'irma_button.dart';
import 'irma_dialog.dart';
import 'irma_repository_provider.dart';
import 'irma_themed_button.dart';
import 'translated_text.dart';

class ContactLink extends StatelessWidget {
  final IconData? iconData;
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool hasPadding;

  const ContactLink({
    this.iconData,
    required this.translationKey,
    this.style,
    this.textAlign,
    this.hasPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Link(
      label: translationKey,
      // padding: hasPadding ? null : EdgeInsets.zero, //If has padding use default ListTile padding.
      // translationKey: translationKey,
      // iconData: iconData,
      // style: style,
      // textAlign: textAlign,
      onTap: () async {
        final String address = FlutterI18n.translate(context, 'help.contact');
        final String subject = Uri.encodeComponent(FlutterI18n.translate(context, 'help.mail_subject'));
        final mail = 'mailto:$address?subject=$subject';
        try {
          await IrmaRepositoryProvider.of(context).openURLExternally(mail);
        } catch (_) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return IrmaDialog(
                title: FlutterI18n.translate(context, 'help.mail_error_title'),
                content: FlutterI18n.translate(context, 'help.mail_error'),
                child: IrmaButton(
                  size: IrmaButtonSize.small,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  label: FlutterI18n.translate(context, 'help.mail_error_button'),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const Link({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      key: const Key('irma_link'),
      child: InkWell(
        onTap: onTap,
        child: TranslatedText(
          label,
          style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                decoration: TextDecoration.underline,
              ),
        ),
      ),
    );
  }
}
