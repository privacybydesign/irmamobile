// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/heading.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/link.dart';

import 'demo_items.dart';
import 'help_items.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = '/help';
  static Key myKey = const Key(routeName);

  final CredentialType credentialType;

  HelpScreen({this.credentialType}) : super(key: myKey);

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'help.title',
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              key: _scrollviewKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              child: Heading(
                                FlutterI18n.translate(context, 'manual.faq'),
                                key: const Key('help_screen_heading'),
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).tinySpacing),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              FlutterI18n.translate(context, 'manual.faq_info'),
                              style: Theme.of(context).textTheme.bodyText2,
                              textAlign: TextAlign.left,
                              key: const Key('help_screen_content'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    DemoItems(
                      credentialType: widget.credentialType,
                      parentKey: _scrollviewKey,
                      parentScrollController: _controller,
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              child: Heading(
                                FlutterI18n.translate(context, 'help.faq'),
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).tinySpacing),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              FlutterI18n.translate(context, 'help.faq_info'),
                              style: Theme.of(context).textTheme.bodyText2,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    HelpItems(
                      credentialType: widget.credentialType,
                      parentKey: _scrollviewKey,
                      parentScrollController: _controller,
                    ),
                    SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                    Center(
                      child: Link(
                        label: FlutterI18n.translate(context, 'help.more'),
                        onTap: () {
                          try {
                            IrmaRepository.get().openURL(FlutterI18n.translate(context, 'help.more_link'));
                          } on PlatformException catch (e, stacktrace) {
                            //TODO: consider if we want an error screen here
                            reportError(e, stacktrace);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: IrmaTheme.of(context).largeSpacing),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              child: Heading(
                                FlutterI18n.translate(context, 'help.ask'),
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).smallSpacing),
                          Text(
                            FlutterI18n.translate(context, 'help.send'),
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                          SizedBox(height: IrmaTheme.of(context).smallSpacing),
                          Center(
                            child: Link(
                              onTap: () async {
                                final String address = FlutterI18n.translate(context, 'help.contact');
                                final String subject =
                                    Uri.encodeComponent(FlutterI18n.translate(context, 'help.mail_subject'));
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
                              label: FlutterI18n.translate(context, 'help.email'),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: IrmaTheme.of(context).backgroundBlue,
                border: Border(
                  top: BorderSide(
                    color: IrmaTheme.of(context).primaryLight,
                    width: 2.0,
                  ),
                ),
              ),
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(
                  vertical: IrmaTheme.of(context).defaultSpacing * 1.5, horizontal: IrmaTheme.of(context).largeSpacing),
              child: IrmaButton(
                label: 'help.back_button',
                key: const Key('back_to_wallet_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
