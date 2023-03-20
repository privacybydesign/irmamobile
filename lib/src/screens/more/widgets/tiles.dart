import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:share/share.dart';

import '../../../sentry/sentry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_dialog.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/translated_text.dart';
import '../../../widgets/yivi_themed_button.dart';

class ContactLinkTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;

  const ContactLinkTile({
    Key? key,
    this.iconData,
    required this.labelTranslationKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
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
                child: YiviThemedButton(
                  label: 'help.mail_error_button',
                  onPressed: () => Navigator.pop(context),
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
    Key? key,
    required this.iconData,
    required this.labelTranslationKey,
    required this.shareTextKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
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
  final IconData? iconData;
  final String labelTranslationKey;
  final String urlLinkKey;

  const ExternalLinkTile({
    Key? key,
    this.iconData,
    required this.labelTranslationKey,
    required this.urlLinkKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
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
  final IconData? iconData;
  final String labelTranslationKey;
  final String routeName;

  const InternalLinkTile({
    Key? key,
    this.iconData,
    required this.labelTranslationKey,
    required this.routeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () => Navigator.pushNamed(context, routeName),
    );
  }
}

class ToggleTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final void Function(bool) onChanged;
  final Stream<bool> stream;

  const ToggleTile({
    Key? key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onChanged,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final value = snapshot.hasData && snapshot.data!;

        return Tile(
          iconData: iconData,
          labelTranslationKey: labelTranslationKey,
          onTap: () => onChanged(!value),
          trailing: CupertinoSwitch(
            value: value,
            onChanged: null, // We use the onTap on the Tile
            activeColor: theme.success,
          ),
        );
      },
    );
  }
}

class Tile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final Function() onTap;
  final Widget? trailing;

  const Tile({
    Key? key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final iconColor = theme.secondary;

    return Semantics(
      link: true,
      child: ListTile(
        onTap: onTap,
        minLeadingWidth: theme.mediumSpacing,
        leading: iconData != null
            ? Icon(
                iconData,
                size: 32,
                color: iconColor,
              )
            : null,
        title: TranslatedText(
          labelTranslationKey,
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              size: 28,
              color: iconColor,
            ),
      ),
    );
  }
}
