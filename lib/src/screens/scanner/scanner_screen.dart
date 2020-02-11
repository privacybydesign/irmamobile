import 'dart:convert';

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

  static void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onSuccess(BuildContext context, String code) {
    startSessionAndNavigate(context, SessionPointer.fromJson(jsonDecode(code) as Map<String, dynamic>));
  }

  // TODO: Make this function private again and / or split it out to a utility function
  static void startSessionAndNavigate(BuildContext context, SessionPointer sessionPointer) {
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
        actions: const [],
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
