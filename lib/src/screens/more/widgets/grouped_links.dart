import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:share/share.dart';

import '../../../data/irma_repository.dart';
import '../../../sentry/sentry.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_dialog.dart';
import '../../../widgets/irma_themed_button.dart';
import '../../../widgets/translated_text.dart';

// class LinkTile extends StatelessWidget {
//   final IconData iconData;
//   final String labelTranslationKey;
//   final String? routeName;

//   const LinkTile({
//     required this.iconData,
//     required this.labelTranslationKey,
//      this.routeName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       onTap: () => Navigator.pushNamed(context, routeName!),
//       leading: Icon(
//         iconData,
//         size: 32,
//       ),
//       title: TranslatedText(
//         labelTranslationKey,
//       ),
//       trailing: const Icon(
//         Icons.chevron_right_rounded,
//         size: 30,
//       ),
//     );
//   }
// }

class GroupedLinks extends StatelessWidget {
  final List<Widget> children;

  const GroupedLinks({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (var linkTile in children) ...[
              linkTile,
              if (children.last != linkTile) const Divider(),
            ]
          ],
        ),
      ),
    );
  }
}

class ContactLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;

  const ContactLinkTile({
    required this.iconData,
    required this.labelTranslationKey,
  });

  @override
  Widget build(BuildContext context) {
    return LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
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

class ShareLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final String shareTextKey;

  const ShareLinkTile({
    required this.iconData,
    required this.labelTranslationKey,
    required this.shareTextKey,
  });

  @override
  Widget build(BuildContext context) {
    return LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        Share.share(FlutterI18n.translate(context, shareTextKey),
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
      },
    );
  }
}

class ExternalLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final String urlLinkKey;

  const ExternalLinkTile({
    required this.iconData,
    required this.labelTranslationKey,
    required this.urlLinkKey,
  });

  @override
  Widget build(BuildContext context) {
    return LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () {
        try {
          IrmaRepository.get().openURL(
            FlutterI18n.translate(context, urlLinkKey),
          );
        } catch (e, stacktrace) {
          // TODO: consider whether we want error screen here
          reportError(e, stacktrace);
        }
      },
    );
  }
}

class InternalLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final String routeName;

  const InternalLinkTile({
    required this.iconData,
    required this.labelTranslationKey,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () => Navigator.pushNamed(context, routeName),
    );
  }
}

class LinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final Function() onTap;

  const LinkTile({
    required this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        iconData,
        size: 32,
      ),
      title: TranslatedText(
        labelTranslationKey,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 30,
      ),
    );
  }
}
