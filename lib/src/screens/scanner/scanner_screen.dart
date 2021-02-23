import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/issue_wizard/issue_wizard.dart';
import 'package:irmamobile/src/screens/scanner/widgets/qr_scanner.dart';
import 'package:irmamobile/src/screens/session/session.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class ScannerScreen extends StatelessWidget {
  static const routeName = "/scanner";

  static void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onSuccess(BuildContext context, SessionPointer sessionPointer) {
    // QR was scanned using IRMA app's internal QR code scanner, so we know for sure
    // the session continues on a second device. Therefore we can overrule the session pointer.
    sessionPointer.continueOnSecondDevice = true;

    HapticFeedback.vibrate();
    if (sessionPointer.wizard != null) {
      startIssueWizard(Navigator.of(context), sessionPointer);
    } else {
      startSessionAndNavigate(Navigator.of(context), sessionPointer);
    }
  }

  static Future<void> startIssueWizard(NavigatorState navigator, SessionPointer sessionPointer) async {
    try {
      await sessionPointer.validate();
    } catch (e) {
      navigator.pushReplacement(MaterialPageRoute(
        builder: (context) => GeneralErrorScreen(
          errorText: "error starting wizard: ${e.toString()}",
          onTapClose: () => navigator.pop(),
        ),
      ));
      return;
    }

    IrmaRepository.get().dispatch(
      GetIssueWizardContentsEvent(id: sessionPointer.wizard),
      isBridgedEvent: true,
    );

    if (sessionPointer.irmaqr != null) {
      await startSessionAndNavigate(navigator, sessionPointer);
    }

    // Push wizard on top of session screen (if any). If the user cancels the wizard by going back
    // to the wallet, then the session screen is automatically dismissed, which cancels the session.
    navigator.pushNamed(IssueWizardScreen.routeName, arguments: sessionPointer.wizard);
  }

  // TODO: Make this function private again and / or split it out to a utility function
  static Future<void> startSessionAndNavigate(NavigatorState navigator, SessionPointer sessionPointer) async {
    final repo = IrmaRepository.get();
    final event = NewSessionEvent(
      request: sessionPointer,
      inAppCredential: await repo.getInAppCredential(),
    );

    final hasActiveSessions = await repo.hasActiveSessions();
    final wizardActive = await repo.getIssueWizardActive().first;
    repo.dispatch(event, isBridgedEvent: true);

    final args = SessionScreenArguments(
      sessionID: event.sessionID,
      sessionType: event.request.irmaqr,
      hasUnderlyingSession: hasActiveSessions,
      wizardActive: wizardActive,
    );
    if (hasActiveSessions || wizardActive) {
      navigator.pushNamed(SessionScreen.routeName, arguments: args);
    } else {
      navigator.pushNamedAndRemoveUntil(
        SessionScreen.routeName,
        ModalRoute.withName(WalletScreen.routeName),
        arguments: args,
      );
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
