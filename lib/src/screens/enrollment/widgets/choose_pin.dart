import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class ChoosePin extends StatelessWidget {
  static const String routeName = 'choose_pin';
  final FocusNode pinFocusNode;
  final void Function(BuildContext, String) submitPin;
  final void Function(BuildContext) cancelAndNavigate;

  const ChoosePin({
    @required this.submitPin,
    @required this.cancelAndNavigate,
    @required this.pinFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.title'),
        ),
        leadingAction: () => cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: IrmaTheme.of(context).hugeSpacing),
                Text(
                  FlutterI18n.translate(context, 'enrollment.choose_pin.insert_pin'),
                  style: IrmaTheme.of(context).textTheme.body1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: IrmaTheme.of(context).mediumSpacing),
                PinField(
                  focusNode: pinFocusNode,
                  longPin: false,
                  onSubmit: (pin) => submitPin(context, pin),
                ),
                SizedBox(height: IrmaTheme.of(context).smallSpacing),
              ],
            ),
          );
        },
      ),
    );
  }
}
