import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:share/share.dart';

import '../../../sentry/sentry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_dialog.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/irma_themed_button.dart';
import '../../../widgets/translated_text.dart';

class ContactLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;

  const ContactLinkTile({
    required this.iconData,
    required this.labelTranslationKey,
  });

  @override
  Widget build(BuildContext context) {
    return _LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
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
    return _LinkTile(
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
    return _LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () {
        try {
          IrmaRepositoryProvider.of(context).openURL(
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
    return _LinkTile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () => Navigator.pushNamed(context, routeName),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final Function() onTap;

  const _LinkTile({
    required this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final iconColor = theme.secondary;

    return Semantics(
      link: true,
      child: ListTile(
        onTap: onTap,
        minLeadingWidth: theme.mediumSpacing,
        leading: Icon(
          iconData,
          size: 32,
          color: iconColor,
        ),
        title: TranslatedText(
          labelTranslationKey,
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 28,
          color: iconColor,
        ),
      ),
    );
  }
}
