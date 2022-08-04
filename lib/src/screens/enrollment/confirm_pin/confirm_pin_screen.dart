import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/pin_field.dart';

class ConfirmPinScreen extends StatelessWidget {
  static const String routeName = 'confirm_pin';

  final Function(String) submitConfirmationPin;

  final VoidCallback onPrevious;

  const ConfirmPinScreen({
    required this.onPrevious,
    required this.submitConfirmationPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.choose_pin.title',
        leadingAction: onPrevious,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: SingleChildScrollView(
        child: Column(
          key: const Key('enrollment_confirm_pin'),
          children: [
            SizedBox(height: theme.hugeSpacing),
            Text(
              FlutterI18n.translate(context, 'enrollment.choose_pin.confirm_instruction'),
              style: theme.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.mediumSpacing),
            PinField(
              longPin: false,
              onSubmit: submitConfirmationPin,
            ),
            SizedBox(height: theme.smallSpacing),
          ],
        ),
      ),
    );
  }
}
