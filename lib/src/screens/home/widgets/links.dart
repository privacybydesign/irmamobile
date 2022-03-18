import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';
import 'package:share/share.dart';
import '../../../data/irma_repository.dart';
import '../../../sentry/sentry.dart';
import '../../../theme/theme.dart';

class Link extends StatelessWidget {
  final IconData? iconData;
  final String translationKey;
  final Function()? onTap;
  final TextStyle? style;
  final TextAlign? textAlign;

  const Link({required this.translationKey, this.iconData, this.onTap, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: TranslatedText(
        translationKey,
        textAlign: textAlign ?? TextAlign.start,
        style: style ?? IrmaTheme.of(context).textTheme.bodyText2!.copyWith(decoration: TextDecoration.underline),
      ),
      leading: iconData != null
          ? Icon(iconData, size: 30, color: IrmaTheme.of(context).themeData.colorScheme.primary)
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
      {required this.iconData, required this.translationKey, required this.routeName, this.style, this.textAlign});

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

  const ContactLink({this.iconData, required this.translationKey, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Link(
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
