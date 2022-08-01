import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/pin_field.dart';

class ChoosePinScreen extends StatefulWidget {
  static const String routeName = 'choose_pin';

  final void Function(String) onChosePin;
  final VoidCallback onPrevious;

  const ChoosePinScreen({
    required this.onChosePin,
    required this.onPrevious,
  });

  @override
  State<ChoosePinScreen> createState() => _ChoosePinScreenState();
}

class _ChoosePinScreenState extends State<ChoosePinScreen> {
  final FocusNode pinFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'enrollment.choose_pin.title',
        leadingAction: widget.onPrevious,
        leadingTooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
      body: SingleChildScrollView(
        child: Column(
          key: const Key('enrollment_choose_pin'),
          children: [
            SizedBox(height: theme.hugeSpacing),
            Text(
              FlutterI18n.translate(context, 'enrollment.choose_pin.insert_pin'),
              style: theme.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.mediumSpacing),
            PinField(
              focusNode: pinFocusNode,
              longPin: false,
              onSubmit: (pin) => widget.onChosePin(pin),
            ),
            SizedBox(height: theme.smallSpacing),
          ],
        ),
      ),
    );
  }
}
