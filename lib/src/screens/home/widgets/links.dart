import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:share/share.dart';

import '../../../data/irma_repository.dart';
import '../../../sentry/sentry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_dialog.dart';
import '../../../widgets/irma_themed_button.dart';
import '../../../widgets/translated_text.dart';

class Link extends StatelessWidget {
  final IconData? iconData;
  final String translationKey;
  final Function()? onTap;
  final TextStyle? style;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry? padding;

  const Link({
    required this.translationKey,
    this.iconData,
    this.onTap,
    this.style,
    this.textAlign,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: padding,
      onTap: onTap,
      title: TranslatedText(
        translationKey,
        textAlign: textAlign ?? TextAlign.start,
        style: style ?? IrmaTheme.of(context).textTheme.bodyText2!.copyWith(decoration: TextDecoration.underline),
      ),
      leading: iconData != null
          ? Icon(iconData, size: 30, color: IrmaTheme.of(context).themeData.colorScheme.secondary)
          : null,
    );
  }
}

class ExternalLink extends StatelessWidget {
  final IconData iconData;
  final String translationKey;
  final String linkKey;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ExternalLink(
      {required this.iconData, required this.translationKey, required this.linkKey, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Link(
      translationKey: translationKey,
      iconData: iconData,
      style: style,
      onTap: () {
        try {
          IrmaRepository.get().openURL(
            FlutterI18n.translate(context, linkKey),
          );
        } catch (e, stacktrace) {
          // TODO: consider whether we want error screen here
          reportError(e, stacktrace);
        }
      },
    );
  }
}

class InternalLink extends StatelessWidget {
  final IconData iconData;
  final String translationKey;
  final String routeName;
  final TextStyle? style;
  final TextAlign? textAlign;

  const InternalLink(
      {Key? key,
      required this.iconData,
      required this.translationKey,
      required this.routeName,
      this.style,
      this.textAlign})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Link(
      translationKey: translationKey,
      iconData: iconData,
      style: style,
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}

class ShareLink extends StatelessWidget {
  final IconData iconData;
  final String translationKey;
  final String shareTextKey;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ShareLink(
      {required this.iconData, required this.translationKey, required this.shareTextKey, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Link(
      translationKey: translationKey,
      iconData: iconData,
      style: style,
      onTap: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        Share.share(FlutterI18n.translate(context, shareTextKey),
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
      },
    );
  }
}

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
      padding: hasPadding ? null : EdgeInsets.zero, //If has padding use default ListTile padding.
      translationKey: translationKey,
      iconData: iconData,
      style: style,
      textAlign: textAlign,
      onTap: () async {
        final String address = FlutterI18n.translate(context, 'help.contact');
        final String subject = Uri.encodeComponent(FlutterI18n.translate(context, 'help.mail_subject'));
        final mail = 'mailto:$address?subject=$subject';
        try {
          await IrmaRepository.get().openURLExternally(mail);
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
