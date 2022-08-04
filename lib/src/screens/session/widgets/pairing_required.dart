import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/session/widgets/session_scaffold.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';
import 'package:irmamobile/src/widgets/pin_box.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class PairingRequired extends StatelessWidget {
  final String pairingCode;
  final Function() onDismiss;

  const PairingRequired({required this.pairingCode, required this.onDismiss});

  Widget _buildPinBoxes(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final boxes = List<Widget>.generate(
      pairingCode.length,
      (i) => PinBox(
        height: 60,
        margin: EdgeInsets.only(right: i == pairingCode.length - 1 ? 0 : theme.smallSpacing),
        char: pairingCode[i],
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64),
          child: Wrap(children: boxes),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return IrmaBottomBar(
      secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.cancel"),
      onSecondaryPressed: () => onDismiss(),
    );
  }

  @override
  Widget build(BuildContext context) => SessionScaffold(
        appBarTitle: 'session.pairing.title',
        bottomNavigationBar: _buildNavigationBar(context),
        onDismiss: onDismiss,
        body: Container(
          margin: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          child: Column(
            children: [
              const IrmaMessage(
                'session.pairing.message_title',
                'session.pairing.message_body_markdown',
              ),
              SizedBox(
                height: IrmaTheme.of(context).defaultSpacing,
              ),
              const TranslatedText('session.pairing.explanation'),
              SizedBox(
                height: IrmaTheme.of(context).largeSpacing,
              ),
              _buildPinBoxes(context),
            ],
          ),
        ),
      );
}
