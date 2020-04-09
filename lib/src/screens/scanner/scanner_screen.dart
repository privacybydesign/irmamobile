import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure_screen.dart';
import 'package:irmamobile/src/screens/disclosure/issuance_screen.dart';
import 'package:irmamobile/src/screens/disclosure/session.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = "/scanner";

  static void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onSuccess(BuildContext context, SessionPointer sessionPointer) {
    startSessionAndNavigate(
      Navigator.of(context),
      sessionPointer,
    );
  }

  // TODO: Make this function private again and / or split it out to a utility function
  static void startSessionAndNavigate(
    NavigatorState navigator,
    SessionPointer sessionPointer, {
    bool continueOnSecondDevice = true,
  }) {
    final event = NewSessionEvent(request: sessionPointer, continueOnSecondDevice: continueOnSecondDevice);
    IrmaRepository.get().dispatch(event, isBridgedEvent: true);

    if (["disclosing", "signing"].contains(event.request.irmaqr)) {
      navigator.pushNamedAndRemoveUntil(
        DisclosureScreen.routeName,
        ModalRoute.withName(WalletScreen.routeName),
        arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
      );
    } else if ("issuing" == event.request.irmaqr) {
      navigator.pushNamedAndRemoveUntil(
        IssuanceScreen.routeName,
        ModalRoute.withName(WalletScreen.routeName),
        arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
      );
    } else {
      // TODO show error
      // TODO handle static QRs
      navigator.popUntil(ModalRoute.withName(WalletScreen.routeName));
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
