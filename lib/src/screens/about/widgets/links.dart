import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLink extends StatelessWidget {
  final String link;
  final String linkText;
  final Widget icon;

  const ExternalLink(this.link, this.linkText, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: IrmaTheme.of(context).defaultSpacing * 3,
          ),
          child: Container(
            child: Padding(
              padding: EdgeInsets.only(
                  left: IrmaTheme.of(context).smallSpacing, right: IrmaTheme.of(context).defaultSpacing),
              child: icon,
            ),
          ),
        ),
        Expanded(
          child: Container(
            child: InkWell(
              onTap: () {
                try {
                  IrmaRepository.get().openURL(
                    context,
                    FlutterI18n.translate(context, link),
                  );
                } on PlatformException catch (e, stacktrace) {
                  // TODO: consider whether we want error screen here
                  reportError(e, stacktrace);
                }
              },
              child: Text(
                FlutterI18n.translate(context, linkText),
                style: TextStyle(
                  color: IrmaTheme.of(context).linkColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InternalLink extends StatelessWidget {
  final String link;
  final String linkText;
  final Widget icon;

  const InternalLink(this.link, this.linkText, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: IrmaTheme.of(context).defaultSpacing * 3,
          ),
          child: Container(
            child: Padding(
              padding: EdgeInsets.only(
                  left: IrmaTheme.of(context).smallSpacing, right: IrmaTheme.of(context).defaultSpacing),
              child: icon,
            ),
          ),
        ),
        Expanded(
          child: Container(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, link);
              },
              child: Text(
                FlutterI18n.translate(context, linkText),
                style: TextStyle(
                  color: IrmaTheme.of(context).linkColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShareLink extends StatelessWidget {
  final String shareText;
  final String displayText;

  final Icon icon;

  const ShareLink(this.shareText, this.displayText, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: IrmaTheme.of(context).defaultSpacing * 3,
          ),
          child: Container(
            child: Padding(
              padding: EdgeInsets.only(
                  left: IrmaTheme.of(context).smallSpacing, right: IrmaTheme.of(context).defaultSpacing),
              child: icon,
            ),
          ),
        ),
        Expanded(
          child: Container(
            child: InkWell(
              onTap: () {
                final RenderBox box = context.findRenderObject() as RenderBox;
                Share.share(shareText, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
              },
              child: Text(
                FlutterI18n.translate(context, displayText),
                style: TextStyle(
                  color: IrmaTheme.of(context).linkColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ContactLink extends StatelessWidget {
  const ContactLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: IrmaTheme.of(context).defaultSpacing * 3,
          ),
          child: Container(
            child: Padding(
              padding: EdgeInsets.only(
                  left: IrmaTheme.of(context).smallSpacing, right: IrmaTheme.of(context).defaultSpacing),
              child: Icon(IrmaIcons.email),
            ),
          ),
        ),
        Expanded(
          // TODO: make one general widget for all spots where we offer contact possibilities
          child: InkWell(
            onTap: () async {
              final String address = FlutterI18n.translate(context, 'about.contact');
              final String subject = Uri.encodeComponent(FlutterI18n.translate(context, 'about.contact_subject'));
              final mail = 'mailto:$address?subject=$subject';
              if (await canLaunch(mail)) {
                await launch(mail);
              } else {
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
            child: Text(
              FlutterI18n.translate(context, 'about.contact'),
              style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
