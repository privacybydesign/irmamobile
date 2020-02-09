import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
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
    const String signingSessionRequest = """
      {
        "@context": "https://irma.app/ld/request/signature/v2",
        "message": "Ik geef hierbij toestemming aan Partij A om mijn gegevens uit te wisselen met Partij B. Deze toestemming is geldig tot 1 juni 2019.",
        "disclose": [
          [
            [
              "pbdf.sidn-pbdf.irma.pseudonym"
            ]
          ]
        ]
      }
    """;

    const String issuanceSessionRequest = """
      {
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [{
          "credential": "irma-demo.MijnOverheid.ageLower",
          "validity": 1592438400,
          "attributes": {
            "over12": "yes",
            "over16": "yes",
            "over18": "yes",
            "over21": "no"
          }
        }]
      }
    """;

    final request = await HttpClient().postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(issuanceSessionRequest);

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

    if (["disclosing", "signing"].contains(event.request.irmaqr)) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          DisclosureScreen.routeName, ModalRoute.withName(WalletScreen.routeName),
          arguments: DisclosureScreenArguments(sessionID: event.sessionID));
    } else {
      Navigator.of(context).popUntil(ModalRoute.withName(WalletScreen.routeName));
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
