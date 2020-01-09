import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({@required this.isEnrolled, Key key}) : super(key: key);

  final bool isEnrolled;

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinBloc = PinBloc();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinBloc, PinState>(
      bloc: _pinBloc,
      builder: (context, state) {
        if (state.isBlocked) {
          return const Scaffold(
            body: Center(child: Text("blocked")),
          );
        }

        if (!widget.isEnrolled || !state.locked) {
          return Container();
        }

        return Scaffold(
            body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                SvgPicture.asset('assets/non-free/irma_logo.svg'),
                SizedBox(
                  height: IrmaTheme.of(context).largeSpacing,
                ),
                Text(
                  FlutterI18n.translate(context, "pin.title"),
                  style: IrmaTheme.of(context).textTheme.display1,
                ),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                Text(FlutterI18n.translate(context, "pin.subtitle")),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                PinField(
                  longPin: false,
                  onSubmit: (pin) {
                    FocusScope.of(context).requestFocus();
                    _pinBloc.dispatch(
                      Unlock(pin),
                    );
                  },
                ),
                SizedBox(
                  height: IrmaTheme.of(context).largeSpacing,
                ),
                GestureDetector(
                  onTap: () {
                    // TODO navigate to screen
                  },
                  child: Text(
                    FlutterI18n.translate(context, "pin.button_forgot"),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                GestureDetector(
                  onTap: () {
                    debugPrint("on block press");
                  },
                  child: Text(
                    FlutterI18n.translate(context, "pin.button_block"),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                SizedBox(
                  height: IrmaTheme.of(context).defaultSpacing,
                ),
                if (state.unlockInProgress)
                  Padding(
                      padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
                      child: const CircularProgressIndicator()),
                if (state.pinInvalid)
                  Text(
                    FlutterI18n.plural(context, "pin.invalid_pin.attempts", state.remainingAttempts),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          color: Colors.red,
                        ),
                    textAlign: TextAlign.center,
                  ),
                if (state.errorMessage != null)
                  Text(
                    FlutterI18n.translate(context, state.errorMessage),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          color: Colors.red,
                        ),
                  )
              ],
            ),
          ),
        ));
      },
    );
  }
}
