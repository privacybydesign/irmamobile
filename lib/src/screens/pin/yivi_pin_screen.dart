library pin;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/util/scale.dart';

import '../../theme/theme.dart';
import '../../widgets/link.dart';
import 'bloc/pin_quality.dart';
import 'secure_pin_bottom_sheet.dart';

part 'bloc/pin_size.dart';
part 'bloc/pin_visibility.dart';
part 'circle_clip.dart';
part 'indicators/hidden_pin.dart';
part 'indicators/visible_pin.dart';
part 'number_pad.dart';
part 'yivi_secure_pin_screen.dart';

typedef NumberFn = void Function(int);
typedef PinFn = void Function(Pin);

// TODO change to branch ux-2.0-yivi-style YiviThemeData default
const defaultHorizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);

int _minPinSize = 5;

Widget _resize(double edgeSize, Widget widget) {
  return SizedBox(
    width: edgeSize,
    height: edgeSize,
    child: widget,
  );
}

class YiviPinScreen extends StatelessWidget {
  final int maxPinSize;
  final PinFn onPinEntered;
  final VoidCallback onCompletePin;
  final PinStream pinStream;
  final _PinSizeBloc pinSizeBloc;
  final _PinVisibilityBloc pinVisibilityBloc;
  final VoidCallback? onForgotPin;
  final VoidCallback? onTogglePinSize;
  final bool checkSecurePin;
  final String instructionKey;

  const YiviPinScreen({
    Key? key,
    required this.instructionKey,
    required this.pinStream,
    required this.pinVisibilityBloc,
    required this.pinSizeBloc,
    required this.maxPinSize,
    required this.onPinEntered,
    required this.onCompletePin,
    this.onForgotPin,
    this.onTogglePinSize,
    this.checkSecurePin = false,
  }) : super(key: key);

  Widget _visibilityButton(BuildContext context, IrmaThemeData theme, IconData icon, VoidCallback fn) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100.0),
        child: Ink(
          width: 60.0.scale(context),
          height: 60.scale(context),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: InkWell(
            onTap: fn,
            child: Icon(
              icon,
              size: 24,
              color: theme.pinIndicatorDarkBlue,
            ),
          ),
        ),
      );

  Widget _activateNext(BuildContext context, IrmaThemeData theme, bool activate) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(48.scale(context)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          primary: theme.pinIndicatorDarkBlue,
        ),
        onPressed: activate ? onCompletePin : null,
        child: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.next'),
          style: theme.textTheme.button?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _pinVisibility(BuildContext context, IrmaThemeData theme, _PinVisibilityBloc bloc) =>
      BlocBuilder<_PinVisibilityBloc, bool>(
        bloc: pinVisibilityBloc,
        builder: (context, visible) => _visibilityButton(
            context, theme, visible ? Icons.visibility_off : Icons.visibility, () => pinVisibilityBloc.add(!visible)),
      );

  Widget _securePinTextButton() => UnsecurePinWarningTextButton(
        pinStream: pinStream,
        bloc: PinQualityBloc(pinStream),
      );

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
          'min viewport width: ${min<double>(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width)}');
    }

    final theme = IrmaTheme.of(context);

    final instruction = Text(
      FlutterI18n.translate(context, instructionKey),
      style: theme.textTheme.headline3?.copyWith(fontWeight: FontWeight.w700),
    );

    final pinDots = BlocBuilder<_PinVisibilityBloc, bool>(
      bloc: pinVisibilityBloc,
      builder: (context, visible) => AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 65.scale(context)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: maxPinSize == _minPinSize
                ? null
                : Border(
                    bottom: BorderSide(color: theme.darkPurple),
                  ),
          ),
          child: visible
              ? _VisiblePinIndicator(
                  maxPinSize: maxPinSize,
                  pinStream: pinStream,
                )
              : _HiddenPinIndicator(
                  maxPinSize: maxPinSize,
                  pinSizeBloc: pinSizeBloc,
                ),
        ),
      ),
    );

    final _togglePinSizeCopy =
        maxPinSize > _minPinSize ? 'change_pin.choose_pin.switch_short' : 'change_pin.choose_pin.switch_long';

    final nextButton = BlocBuilder<_PinSizeBloc, int>(
      bloc: pinSizeBloc,
      builder: (context, size) => _activateNext(context, theme, size >= (_minPinSize == maxPinSize ? 5 : 6)),
    );

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            children: [
              SizedBox.square(dimension: 42.scale(context)),
              SizedBox(
                height: 71.scale(context),
                width: 127.scale(context),
                // TODO replace with Yivi logo on ux-2.0-yivi-style branch
                child: Image.asset("assets/non-free/irmalogo.png", excludeFromSemantics: true),
              ),
              SizedBox(height: 32.scale(context)),
              Center(
                child: instruction,
              ),
              SizedBox(height: 32.scale(context)),
              Stack(
                alignment: Alignment.center,
                children: [
                  pinDots,
                  Align(
                    alignment: Alignment.centerRight,
                    child: _pinVisibility(context, theme, pinVisibilityBloc),
                  ),
                ],
              ),
              // SizedBox(height: 10.scale(context)),
              if (checkSecurePin)
                Center(
                  child: _securePinTextButton(),
                ),
              // if (onTogglePinSize != null && checkSecurePin) SizedBox.square(dimension: 8.scale(context)),
              if (onTogglePinSize != null)
                Center(
                  child: Link(
                    onTap: onTogglePinSize!,
                    label: FlutterI18n.translate(context, _togglePinSizeCopy),
                  ),
                ),
              if (onForgotPin != null)
                Center(
                  child: Link(
                    onTap: onForgotPin,
                    label: FlutterI18n.translate(context, 'pin.button_forgot'),
                  ),
                ),
            ],
          ),
        ),
        _NumberPad(
          onEnterNumber: (i) {
            final newPin = pinStream.value;
            if (i < 0) {
              if (pinStream.value.isNotEmpty) {
                newPin.removeLast();
              }
            } else if (pinStream.value.length < maxPinSize) {
              newPin.add(i);
            }
            onPinEntered(newPin);
          },
        ),
        nextButton
      ],
    );

    return Scaffold(
      backgroundColor: theme.background,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: body,
        ),
      ),
    );
  }
}

class PinScreenTest extends StatelessWidget {
  late final _PinSizeBloc pinSizeBloc;
  final pinVisibilityBloc = _PinVisibilityBloc();

  final pinStream = PinStream.seeded([]);

  final int maxPinSize;
  final VoidCallback? onTogglePinSize;

  PinScreenTest({required this.maxPinSize, this.onTogglePinSize}) {
    pinSizeBloc = _PinSizeBloc(pinStream);
  }

  @override
  Widget build(BuildContext context) {
    return YiviPinScreen(
      instructionKey: 'pin.title',
      maxPinSize: maxPinSize,
      onPinEntered: (pin) {
        pinStream.sink.add(pin);
      },
      onCompletePin: () => Navigator.pop(context),
      pinSizeBloc: pinSizeBloc,
      pinVisibilityBloc: pinVisibilityBloc,
      pinStream: pinStream,
      onForgotPin: () => Navigator.pop(context),
      onTogglePinSize: onTogglePinSize,
    );
  }
}
