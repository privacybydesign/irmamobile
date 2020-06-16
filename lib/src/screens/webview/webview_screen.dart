import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/webview/widgets/browser_bar.dart';
import 'package:irmamobile/src/screens/webview/widgets/loading_data.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScreen extends StatefulWidget {
  static const String routeName = "/issuance/webview";
  final String url;

  void _handleSessionPointer(BuildContext context, SessionPointer sessionPointer) {
    ScannerScreen.startSessionAndNavigate(Navigator.of(context), sessionPointer, webview: true);
  }

  const WebviewScreen(this.url, {Key key}) : super(key: key);

  @override
  _WebviewScreenState createState() => _WebviewScreenState(url);
}

class _WebviewScreenState extends State<WebviewScreen> with WidgetsBindingObserver {
  String _url;
  bool _isLoading;

  _WebviewScreenState(this._url) : _isLoading = true;
  SessionPointer _sessionPointer;

  @override
  void initState() {
    final uri = Uri.parse(_url);
    _url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      "inapp": "true", // Make sure the in-app variant of the website is requested
    }).toString();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openInBrowser() {
    final uri = Uri.parse(_url);
    final externalUrl = uri.replace(queryParameters: {...uri.queryParameters}..remove("inapp")).toString();
    IrmaRepository.get().openURLinBrowser(context, externalUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrowserBar(
        url: _url,
        onOpenInBrowserPress: _openInBrowser,
        isLoading: _isLoading,
      ),
      body: _sessionPointer == null
          ? Stack(
              children: <Widget>[
                WebView(
                  javascriptMode: JavascriptMode.unrestricted,
                  initialUrl: _url,
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
                        _url = navrequest.url;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Workaround to prevent that input fields in the webview become unresponsive when app is
    // paused and resumed again. This is caused by a Flutter webview bug in Android 10. By
    // pushing a new route over the webview screen and pop it again, the webview becomes
    // responsive again. Remove code when Flutter webview bugs are solved.
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      final loadingRoute = MaterialPageRoute(builder: (context) {
        return LoadingScreen();
      });
      Navigator.of(context).push(loadingRoute);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (loadingRoute.isCurrent) {
          Navigator.of(context).pop();
        }
      });
    }
    super.didChangeAppLifecycleState(state);
  }
}
