import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:url_launcher/url_launcher.dart';

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
                              child: Text(
                                FlutterI18n.translate(context, 'demo.faq'),
                                style: Theme.of(context).textTheme.display2,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).tinySpacing),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              FlutterI18n.translate(context, 'demo.faq_info'),
                              style: Theme.of(context).textTheme.body1,
                              textAlign: TextAlign.left,
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
                              child: Text(
                                FlutterI18n.translate(context, 'help.faq'),
                                style: Theme.of(context).textTheme.display2,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).tinySpacing),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              FlutterI18n.translate(context, 'help.faq_info'),
                              style: Theme.of(context).textTheme.body1,
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
                    GestureDetector(
                      onTap: () {
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return WebviewScreen(FlutterI18n.translate(context, 'help.more_link'));
                            }),
                          );
                        } on PlatformException catch (e) {
                          debugPrint(e.toString());
                          debugPrint("error on launch of url - probably bad certificate?");
                        }
                      },
                      child: Center(
                        child: Text(
                          FlutterI18n.translate(context, 'help.more'),
                          style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                        ),
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
                              child: Text(
                                FlutterI18n.translate(context, 'help.ask'),
                                style: Theme.of(context).textTheme.display2,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          SizedBox(height: IrmaTheme.of(context).smallSpacing),
                          Text(
                            FlutterI18n.translate(context, 'help.send'),
                            style: Theme.of(context).textTheme.body1,
                          ),
                          SizedBox(height: IrmaTheme.of(context).smallSpacing),
                          GestureDetector(
                            onTap: () async {
                              final String address = FlutterI18n.translate(context, 'help.contact');
                              final String subject =
                                  Uri.encodeComponent(FlutterI18n.translate(context, 'help.mail_subject'));
                              final mail = 'mailto:$address?subject=$subject';
                              if (await canLaunch(mail)) {
                                await launch(mail);
                              } else {
                                showDialog(
                                  context: context,
                                  // TODO I am not sure whether it should be  builder: (_) instead (also seems to work)
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
                            child: Center(
                              child: Text(
                                FlutterI18n.translate(context, 'help.email'),
                                style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
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
