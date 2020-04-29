import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
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
    HapticFeedback.vibrate();
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
    final repo = IrmaRepository.get();
    repo.dispatch(event, isBridgedEvent: true);

    if (["disclosing", "signing", "static"].contains(event.request.irmaqr)) {
      // TODO test static QRs
      navigator.pushNamedAndRemoveUntil(
        DisclosureScreen.routeName,
        ModalRoute.withName(WalletScreen.routeName),
        arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
      );
    } else if ("issuing" == event.request.irmaqr) {
      // In this case we have to wait with navigating to the relevant screen
      // until we know if this is a combined disclosure-issuance request
      repo
          .getSessionState(event.sessionID)
          .firstWhere((session) => [
                SessionStatus.requestPermission,
                SessionStatus.canceled,
                SessionStatus.error,
              ].contains(session.status))
          .then((session) {
        navigator.pushNamedAndRemoveUntil(
          (session.disclosureChoices?.isEmpty ?? true) ? IssuanceScreen.routeName : DisclosureScreen.routeName,
          ModalRoute.withName(WalletScreen.routeName),
          arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
        );
      });
    } else {
      // TODO show error?
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
