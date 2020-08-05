import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bool webview = false,
  }) {
    final repo = IrmaRepository.get();
    repo.hasActiveSessions().then((hasActiveSessions) {
      final event = NewSessionEvent(request: sessionPointer, continueOnSecondDevice: continueOnSecondDevice);
      repo.dispatch(event, isBridgedEvent: true);

      String screen;
      if (["disclosing", "signing", "redirect"].contains(event.request.irmaqr)) {
        screen = DisclosureScreen.routeName;
      } else if ("issuing" == event.request.irmaqr) {
        screen = IssuanceScreen.routeName;
      } else {
        // TODO show error?
        navigator.popUntil(ModalRoute.withName(WalletScreen.routeName));
        return;
      }
      if (hasActiveSessions) {
        // After this session finishes, we want to go back to the previous session
        if (webview) {
          // replace webview with session screen
          navigator.pushReplacementNamed(
            screen,
            arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
          );
        } else {
          // webview is already dismissed, just push the session screen
          navigator.pushNamed(
            screen,
            arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
          );
        }
      } else {
        navigator.pushNamedAndRemoveUntil(
          DisclosureScreen.routeName,
          ModalRoute.withName(WalletScreen.routeName),
          arguments: SessionScreenArguments(sessionID: event.sessionID, sessionType: event.request.irmaqr),
        );
      }
    });
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
