library pin;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/util/scale.dart';

import '../../theme/theme.dart';
import '../../util/secure_pin.dart';
import '../../widgets/link.dart';
import '../../widgets/yivi_bottom_sheet.dart';

part 'bloc/pin_visibility.dart';
part 'bloc/yivi_pin_bloc.dart';
part 'circle_clip.dart';
part 'number_pad.dart';
part 'secure_pin_bottom_sheet.dart';
part 'yivi_pin_indicator.dart';

typedef Pin = List<int>;
typedef PinFn = bool Function(Pin);
typedef PinQuality = Set<SecurePinAttribute>;
typedef NumberFn = void Function(int);

// TODO change to branch ux-2.0-yivi-style YiviThemeData default
const _paddingInPx = 16.0;

const _nextButtonHeight = 48.0;

const shortPinSize = 5;
const longPinSize = 16;

Widget _resizeBox(Widget widget, double edge) => SizedBox(
      width: edge,
      height: edge,
      child: widget,
    );

class YiviPinScreen extends StatelessWidget {
  final int maxPinSize;
  final VoidCallback onSubmit;
  final PinStateBloc pinBloc;
  final PinVisibilityBloc pinVisibilityBloc;
  final VoidCallback? onForgotPin;
  final VoidCallback? onTogglePinSize;
  final bool checkSecurePin;
  final String instructionKey;

  const YiviPinScreen({
    Key? key,
    required this.instructionKey,
    required this.pinVisibilityBloc,
    required this.pinBloc,
    required this.maxPinSize,
    required this.onSubmit,
    this.onForgotPin,
    this.onTogglePinSize,
    this.checkSecurePin = false,
  }) : super(key: key);

  Widget _visibilityButton(BuildContext context, IrmaThemeData theme, IconData icon, VoidCallback fn) => ClipPath(
        clipper: _PerfectCircleClip(),
        child: Material(
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
        ),
      );

  Widget _activateNext(BuildContext context, IrmaThemeData theme, bool activate) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(_nextButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          primary: theme.pinIndicatorDarkBlue,
        ),
        onPressed: activate ? onSubmit : null,
        child: Text(
          FlutterI18n.translate(context, 'enrollment.choose_pin.next'),
          style: theme.textTheme.button?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _pinVisibility(BuildContext context, IrmaThemeData theme, PinVisibilityBloc bloc) =>
      BlocBuilder<PinVisibilityBloc, bool>(
        bloc: pinVisibilityBloc,
        builder: (context, visible) => _visibilityButton(
            context, theme, visible ? Icons.visibility_off : Icons.visibility, () => pinVisibilityBloc.add(!visible)),
      );

  Widget _securePinTextButton() => UnsecurePinWarningTextButton(bloc: pinBloc);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final instruction = Text(
      FlutterI18n.translate(context, instructionKey),
      style: theme.textTheme.headline3?.copyWith(fontWeight: FontWeight.w700),
    );

    final pinDots = BlocBuilder<PinStateBloc, PinState>(
      bloc: pinBloc,
      builder: (context, state) =>
          _PinIndicator(maxPinSize: maxPinSize, visibilityBloc: pinVisibilityBloc, pinState: state),
    );

    final pinDotsDecorated = Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 64.scale(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              pinDots,
              if (maxPinSize != shortPinSize)
                Divider(
                  height: 1.0,
                  color: theme.darkPurple,
                ),
              if (maxPinSize != shortPinSize)
                Align(
                  alignment: Alignment.bottomRight,
                  child: BlocBuilder<PinStateBloc, PinState>(
                    bloc: pinBloc,
                    builder: (context, state) => Text(
                      '${state.pin.length}/$maxPinSize',
                      style: theme.textTheme.caption?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: state.pin.isNotEmpty ? theme.darkPurple : Colors.transparent),
                    ),
                  ),
                )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: maxPinSize == shortPinSize ? 0.0 : 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: _pinVisibility(context, theme, pinVisibilityBloc),
          ),
        ),
      ],
    );

    final togglePinSizeCopy =
        maxPinSize > shortPinSize ? 'change_pin.choose_pin.switch_short' : 'change_pin.choose_pin.switch_long';

    final nextButton = BlocBuilder<PinStateBloc, PinState>(
      bloc: pinBloc,
      builder: (context, state) =>
          _activateNext(context, theme, state.pin.length >= (shortPinSize == maxPinSize ? 5 : 6)),
    );

    List<Widget> bodyPortrait(BuildContext context) => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                SizedBox(height: 16.scale(context)),
                pinDotsDecorated,
                if (checkSecurePin)
                  Center(
                    child: _securePinTextButton(),
                  ),
                if (onTogglePinSize != null)
                  Center(
                    child: Link(
                      onTap: onTogglePinSize,
                      label: FlutterI18n.translate(context, togglePinSizeCopy),
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
          Expanded(
            child: _NumberPad(
              onEnterNumber: pinBloc.update,
            ),
          ),
          const SizedBox(height: _paddingInPx),
          nextButton,
        ];

    List<Widget> bodyLandscape(BuildContext context) => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 71.scale(context),
                  width: 127.scale(context),
                  // TODO replace with Yivi logo on ux-2.0-yivi-style branch
                  child: Image.asset("assets/non-free/irmalogo.png", excludeFromSemantics: true),
                ),
                Center(
                  child: instruction,
                ),
                pinDotsDecorated,
                if (checkSecurePin)
                  Center(
                    child: _securePinTextButton(),
                  ),
                if (onTogglePinSize != null)
                  Center(
                    child: Link(
                      onTap: onTogglePinSize,
                      label: FlutterI18n.translate(context, togglePinSizeCopy),
                    ),
                  ),
                if (onForgotPin != null)
                  Center(
                    child: Link(
                      onTap: onForgotPin,
                      label: FlutterI18n.translate(context, 'pin.button_forgot'),
                    ),
                  ),
                nextButton
              ],
            ),
          ),
          Expanded(
            child: _NumberPad(
              onEnterNumber: pinBloc.update,
            ),
          ),
        ];

    return Scaffold(
      backgroundColor: theme.background,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(_paddingInPx),
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (Orientation.portrait == orientation) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: bodyPortrait(context),
                );
              } else {
                return Row(
                  children: bodyLandscape(context),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
