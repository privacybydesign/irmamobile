import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/pin_box.dart';
import 'session_scaffold.dart';

class PairingRequired extends StatelessWidget {
  final String pairingCode;
  final Function() onDismiss;

  const PairingRequired({required this.pairingCode, required this.onDismiss});

  Widget _buildPinBoxes(BuildContext context, IrmaThemeData theme) {
    final boxes = List<Widget>.generate(
      pairingCode.length,
      (i) => PinBox(
        height: 53,
        char: pairingCode[i],
        highlightBorder: true,
        completed: true,
      ),
      growable: false,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: theme.mediumSpacing,
      children: boxes,
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return IrmaBottomBar(
      secondaryButtonLabel: FlutterI18n.translate(context, 'session.navigation_bar.cancel'),
      onSecondaryPressed: () => onDismiss(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SessionScaffold(
      appBarTitle: 'session.pairing.title',
      bottomNavigationBar: _buildNavigationBar(context),
      onDismiss: onDismiss,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IrmaQuote(
                quote: FlutterI18n.translate(
                  context,
                  'session.pairing.instruction',
                ),
                color: const Color(0xFFE9F4FF),
              ),
              SizedBox(
                height: theme.hugeSpacing,
              ),
              _buildPinBoxes(context, theme),
            ],
          ),
        ),
      ),
    );
  }
}
