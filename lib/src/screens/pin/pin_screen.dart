import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_bloc.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
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
            backgroundColor: IrmaTheme.of(context).backgroundBlue,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: IrmaTheme.of(context).defaultSpacing,
                    ),
                    Text(
                      FlutterI18n.translate(context, "pin.title"),
                      style: IrmaTheme.of(context).textTheme.display1,
                    ),
                    SizedBox(
                      height: IrmaTheme.of(context).largeSpacing,
                    ),
                    SizedBox(width: 76.0, child: SvgPicture.asset('assets/non-free/irma_logo.svg')),
                    SizedBox(
                      height: IrmaTheme.of(context).largeSpacing,
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
                      height: IrmaTheme.of(context).defaultSpacing,
                    ),
                    GestureDetector(
                      onTap: () {
                        debugPrint("on forgot pin press");
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
                    if (state.pinInvalid)
                      IrmaDialog(
                        height: 250,
                        title: 'settings.advanced.delete_title',
                        content: 'settings.advanced.delete_content',
                        child: Wrap(
                          direction: Axis.horizontal,
                          verticalDirection: VerticalDirection.up,
                          alignment: WrapAlignment.spaceEvenly,
                          children: <Widget>[
                            IrmaTextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              minWidth: 0.0,
                              label: 'settings.advanced.delete_deny',
                            ),
                            IrmaButton(
                              size: IrmaButtonSize.small,
                              minWidth: 0.0,
                              onPressed: () {},
                              label: 'settings.advanced.delete_confirm',
                            ),
                          ],
                        ),
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
