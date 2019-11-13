import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/screens/issuance_webview/models/session_pointer.dart';
import 'package:irmamobile/src/screens/issuance_webview/widgets/browser_bar.dart';
import 'package:irmamobile/src/screens/issuance_webview/widgets/loading_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IssuanceWebviewScreen extends StatefulWidget {
  static const String routeName = "/issuance/webview";
  final String url;
  final StreamController<SessionPointer> _sessionStreamController = StreamController();

  IssuanceWebviewScreen(this.url, {Key key}) : super(key: key);

  @override
  _IssuanceWebviewScreenState createState() => _IssuanceWebviewScreenState(url);

  Stream get sessionStream => _sessionStreamController.stream;
}

class _IssuanceWebviewScreenState extends State<IssuanceWebviewScreen> {
  final String url;
  bool _isLoading;

  _IssuanceWebviewScreenState(this.url) : _isLoading = true;
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
          Navigator.of(context).pop();
          launch(url);
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
                    setState(() {
                      _isLoading = true;
                    });

                    return NavigationDecision.navigate;
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.ltr,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: const LoadingData(),
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
