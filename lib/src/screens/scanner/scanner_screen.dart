import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure_screen.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = "/scanner";

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onSuccess(BuildContext context, String code) {
    _startSessionAndNavigate(context, SessionPointer.fromJson(jsonDecode(code) as Map<String, dynamic>));
  }

  static Future<void> onDebugSession(BuildContext context) async {
    final Uri uri = Uri.parse("https://metrics.privacybydesign.foundation/irmaserver/session");
    const String sessionRequest = """
      {
        "@context": "https://irma.app/ld/request/disclosure/v2",
        "disclose": [
          [
            [
              "pbdf.sidn-pbdf.irma.pseudonym"
            ]
          ]
        ]
      }
    """;

    final request = await HttpClient().postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(sessionRequest);

    final response = await request.close();
    response.transform(utf8.decoder).listen((responseBody) {
      final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
      final sessionPtr = SessionPointer.fromJson(responseObject["sessionPtr"] as Map<String, dynamic>);

      _startSessionAndNavigate(context, sessionPtr);
    });
  }

  static void _startSessionAndNavigate(BuildContext context, SessionPointer sessionPointer) {
    final event = NewSessionEvent(request: sessionPointer, continueOnSecondDevice: true);
    IrmaRepository.get().dispatch(event, isBridgedEvent: true);

    if (event.request.irmaqr == "disclosing") {
      Navigator.pushNamed(context, DisclosureScreen.routeName,
          arguments: DisclosureScreenArguments(sessionID: event.sessionID));
    } else {
      Navigator.popUntil(context, ModalRoute.withName(WalletScreen.routeName));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text('QR code scan'),
        leadingAction: () => _onClose(context),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
        actions: <Widget>[
          if (!kReleaseMode) IconButton(icon: Icon(Icons.directions_walk), onPressed: () => onDebugSession(context)),
        ],
      ),
      body: Stack(
        children: <Widget>[
          QRScanner(
            onClose: () => _onClose(context),
            onFound: (code) => _onSuccess(context, code),
          ),
        ],
      ),
    );
  }
}
