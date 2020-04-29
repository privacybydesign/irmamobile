import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/webview/widgets/browser_bar.dart';
import 'package:irmamobile/src/screens/webview/widgets/loading_data.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScreen extends StatefulWidget {
  static const String routeName = "/issuance/webview";
  final String url;

  void _handleSessionPointer(BuildContext context, SessionPointer sessionPointer) {
    ScannerScreen.startSessionAndNavigate(Navigator.of(context), sessionPointer);
  }

  const WebviewScreen(this.url, {Key key}) : super(key: key);

  @override
  _WebviewScreenState createState() => _WebviewScreenState(url);
}

class _WebviewScreenState extends State<WebviewScreen> {
  String url;
  bool _isLoading;

  _WebviewScreenState(this.url) : _isLoading = true;
  SessionPointer _sessionPointer;

  @override
  void initState() {
    // Make sure the in-app variant of the website is requested
    final uri = Uri.parse(url);
    url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      "inapp": "true",
    }).toString();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrowserBar(
        url: url,
        onOpenInBrowserPress: () {
          final uri = Uri.parse(url);
          // uri.queryParameters is unmodifiable, so remove item in new map
          final queryParameters = {...uri.queryParameters};
          queryParameters.remove("inapp");
          final externalUrl = uri.replace(queryParameters: queryParameters).toString();
          if (Platform.isAndroid) {
            Navigator.pop(context); // remove ActionSheet // TODO ActionSheet only disappears after returning
            launch(externalUrl);
          } else if (Platform.isIOS) {
            Navigator.pop(context); // remove ActionSheet // TODO ActionSheet only disappears after returning
            launch(externalUrl, forceSafariVC: false); // open Safari rather than SafariVCController
          }
        },
        isLoading: _isLoading,
      ),
      body: _sessionPointer == null
          ? Stack(
              children: <Widget>[
                WebView(
                  javascriptMode: JavascriptMode.unrestricted,
                  initialUrl: url,
                  onPageFinished: (url) {
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  navigationDelegate: (navrequest) {
                    //Ignore navrequests that are not for the main frame
                    if (!navrequest.isForMainFrame) return NavigationDecision.navigate;

                    debugPrint("received nav request ${navrequest.url}");
                    final decodedUri = Uri.decodeFull(navrequest.url);

                    try {
                      _sessionPointer = SessionPointer.fromString(decodedUri);
                    } catch (_) {
                      _sessionPointer = null;
                    }
                    if (_sessionPointer != null) {
                      setState(() {
                        widget._handleSessionPointer(context, _sessionPointer);
                      });
                      return NavigationDecision.prevent;
                    }

                    // Only allow https connections
                    if (navrequest.url.startsWith('https://')) {
                      setState(() {
                        url = navrequest.url;
                        _isLoading = true;
                      });

                      return NavigationDecision.navigate;
                    } else {
                      setState(() {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return IrmaDialog(
                              title: FlutterI18n.translate(context, 'webview.alert_title'),
                              content: FlutterI18n.translate(context, 'webview.alert_message'),
                              child: IrmaButton(
                                size: IrmaButtonSize.small,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                label: FlutterI18n.translate(context, 'webview.alert_button'),
                              ),
                            );
                          },
                        );
                      });
                      debugPrint('blocking navigation to $navrequest}');
                      return NavigationDecision.prevent;
                    }
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.ltr,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: LoadingData(),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
              ],
            ),
    );
  }
}
