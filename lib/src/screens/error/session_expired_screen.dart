import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/session_expired.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class SessionExpiredScreen extends StatelessWidget {
  final VoidCallback onTapClose;

  const SessionExpiredScreen({@required this.onTapClose});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onTapClose();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'error.title',
            ),
          ),
          leadingAction: onTapClose,
        ),
        body: SessionExpired(),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'error.button_back'),
          onPrimaryPressed: onTapClose,
        ),
      ),
    );
  }
}
