import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/screens/pin/widgets/blocked.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import '../../data/irma_preferences.dart';
import '../scanner/scanner_screen.dart';

class PinScreen extends StatefulWidget {
  static const String routeName = '/pin-screen';

  const PinScreen({Key key}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinBloc = PinBloc();

  FocusNode _focusNode;
  StreamSubscription _pinBlocSubscription;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _pinBlocSubscription = _pinBloc.state.listen((pinState) async {
      if (pinState.locked == false) {
        Navigator.of(context).pop();
        final startQrScanner = await IrmaPreferences.get().getStartQRScan().first;
        if (startQrScanner) {
          Navigator.of(context).pushNamed(ScannerScreen.routeName);
        }

        _pinBlocSubscription.cancel();
      }
      if (pinState.pinInvalid) {
        showDialog(
          context: context,
          child: AlertDialog(
            title: Text(
              FlutterI18n.translate(context, "pin.invalid_pin_dialog_title"),
            ),
            content: Text(
              FlutterI18n.plural(context, "pin.invalid_pin.attempts", pinState.remainingAttempts),
            ),
            actions: <Widget>[
              IrmaTextButton(
                label: FlutterI18n.translate(context, "pin.invalid_pin_dialog_close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }

      if (pinState.errorMessage != null) {
        showDialog(
          context: context,
          child: AlertDialog(
            title: Text(
              FlutterI18n.translate(context, "error.title"),
            ),
            content: Text(
              pinState.errorMessage,
            ),
            actions: <Widget>[
              IrmaTextButton(
                label: FlutterI18n.translate(context, "error.button_ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return _pinBloc.currentState.locked == false;
      },
      child: BlocBuilder<PinBloc, PinState>(
        bloc: _pinBloc,
        builder: (context, state) {
          if (state.isBlocked == true) {
            return Scaffold(
              appBar: _buildAppBar(),
              body: Blocked(),
            );
          }

          if (state.locked == false) {
            return Container();
          }

          FocusScope.of(context).requestFocus(_focusNode);
          return Scaffold(
            backgroundColor: IrmaTheme.of(context).backgroundBlue,
            appBar: _buildAppBar(),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: IrmaTheme.of(context).largeSpacing,
                    ),
                    SizedBox(
                      width: 76.0,
                      child: SvgPicture.asset(
                        'assets/non-free/irma_logo.svg',
                        semanticsLabel: FlutterI18n.translate(
                          context,
                          'accessibility.irma_logo',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: IrmaTheme.of(context).largeSpacing,
                    ),
                    Text(FlutterI18n.translate(context, "pin.subtitle")),
                    SizedBox(
                      height: IrmaTheme.of(context).defaultSpacing,
                    ),
                    PinField(
                      focusNode: _focusNode,
                      longPin: false,
                      onSubmit: (pin) {
                        FocusScope.of(context).requestFocus();
                        _pinBloc.dispatch(
                          Unlock(pin),
                        );
                      },
                    ),
                    SizedBox(
                      height: IrmaTheme.of(context).defaultSpacing,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(ResetPinScreen.routeName);
                      },
                      child: Text(
                        FlutterI18n.translate(context, "pin.button_forgot"),
                        style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                    if (state.unlockInProgress)
                      Padding(
                          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
                          child: const CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: IrmaTheme.of(context).backgroundBlue,
      leading: Container(),
      title: Text(
        FlutterI18n.translate(context, "pin.title"),
        style: IrmaTheme.of(context).textTheme.display1,
      ),
    );
  }
}
