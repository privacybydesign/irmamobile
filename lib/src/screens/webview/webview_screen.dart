import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/webview/models/session_pointer.dart';
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
  final StreamController<SessionPointer> _sessionStreamController = StreamController();

  WebviewScreen(this.url, {Key key}) : super(key: key);

  @override
  _WebviewScreenState createState() => _WebviewScreenState(url);

  Stream get sessionStream => _sessionStreamController.stream;
}

class _WebviewScreenState extends State<WebviewScreen> {
  String url;
  bool _isLoading;

  _WebviewScreenState(this.url) : _isLoading = true;
  SessionPointer _sessionPointer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget._sessionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrowserBar(
        url: url,
        onOpenInBrowserPress: () {
          if (Platform.isAndroid) {
            Navigator.pop(context); // remove ActionSheet // TODO ActionSheet only disappears after returning
            launch(url);
          } else if (Platform.isIOS) {
            Navigator.pop(context); // remove ActionSheet // TODO ActionSheet only disappears after returning
            launch(url, forceSafariVC: false); // open Safari rather than SafariVCController
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
                    debugPrint("received nav request ${navrequest.url}");
                    final decodedUri = Uri.decodeFull(navrequest.url);

                    if (_isIRMAURI(decodedUri)) {
                      setState(() {
                        try {
                          _sessionPointer = SessionPointer.fromURI(decodedUri);
                          widget._sessionStreamController.sink.add(_sessionPointer);
                        } catch (err) {
                          debugPrint(err.toString());
                        }
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
                          // TODO I am not sure whether it should be  builder: (_) instead (also seems to work)
                          builder: (BuildContext context) {
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
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: LoadingData(),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text("sessionType: ${_sessionPointer.irmaqr}"),
                Text("sessionURL: ${_sessionPointer.u}")
              ],
            ),
    );
  }

  bool _isIRMAURI(String uri) {
    final regexIrma = RegExp("^irma:\/\/qr\/json\/{");
    final regexIntent = RegExp("^intent:\/\/qr\/json\/{");
    final regexHttp = RegExp("^https:\/\/irma.app\/.+\/session#{");
    return regexIntent.hasMatch(uri) || regexHttp.hasMatch(uri) || regexIrma.hasMatch(uri);
  }
}
