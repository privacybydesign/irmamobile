import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLink extends StatelessWidget {
  final String link;
  final String linkText;
  final Widget icon;

  const ExternalLink(this.link, this.linkText, this.icon);

  void _openURL(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return WebviewScreen(url);
      }),
    );
  }

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
                  _openURL(
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
  final String mailto;
  final String subjectLine;
  final String linkText;
  final Widget icon;

  const ContactLink(this.mailto, this.subjectLine, this.linkText, this.icon);

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
                final String address = FlutterI18n.translate(context, mailto);
                final String subject = FlutterI18n.translate(context, subjectLine);
                launch("mailto:$address?subject=$subject");
              },
              child: Text(
                FlutterI18n.translate(context, linkText),
                style: TextStyle(color: IrmaTheme.of(context).linkColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
