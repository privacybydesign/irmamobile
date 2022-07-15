library pin;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../..//util/tablet.dart';
import '../../theme/theme.dart';
import '../../util/scale.dart';
import '../../util/secure_pin.dart';
import '../../widgets/link.dart';
import '../../widgets/yivi_bottom_sheet.dart';

part 'bloc/pin_visibility.dart';
part 'bloc/yivi_pin_bloc.dart';
part 'circle_clip.dart';
part 'number_pad.dart';
part 'number_pad_key.dart';
part 'secure_pin_bottom_sheet.dart';
part 'yivi_pin_indicator.dart';
part 'yivi_pin_scaffold.dart';

typedef Pin = List<int>;
typedef PinFn = bool Function(Pin);
typedef PinQuality = Set<SecurePinAttribute>;
typedef NumberFn = void Function(int);

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
  final String? instructionKey;
  final String? instruction;
  final bool enabled;
  final void Function(BuildContext, PinState)? listener;

  const YiviPinScreen({
    Key? key,
    this.instructionKey,
    this.instruction,
    required this.pinVisibilityBloc,
    required this.pinBloc,
    required this.maxPinSize,
    required this.onSubmit,
    this.onForgotPin,
    this.onTogglePinSize,
    this.checkSecurePin = false,
    this.enabled = true,
    this.listener,
  })  : assert(instructionKey != null && instruction == null || instruction != null && instructionKey == null),
        super(key: key);

  Widget _securePinTextButton() => UnsecurePinWarningTextButton(bloc: pinBloc);

  /// Some functions are nested to save on ceremony for repeatedly passed parameters
  /// Also nested functions are not exposed outside the parent function
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget visibilityButton(IconData icon, VoidCallback fn) => ClipPath(
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
                  color: theme.secondary,
                ),
              ),
            ),
          ),
        );

    Widget activateNext(bool activate) => ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed))
                  return theme.secondary.withOpacity(0.5);
                else if (states.contains(MaterialState.disabled)) return theme.secondary.withOpacity(0.05);
                return theme.secondary;
              },
            ),
            minimumSize: MaterialStateProperty.resolveWith<Size>((s) => const Size.fromHeight(_nextButtonHeight)),
            shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
              (s) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          onPressed: activate && enabled ? onSubmit : null,
          child: Text(
            FlutterI18n.translate(context, 'enrollment.choose_pin.next'),
            style: theme.textTheme.button?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    Widget pinVisibility(PinVisibilityBloc bloc) => BlocBuilder<PinVisibilityBloc, bool>(
          bloc: pinVisibilityBloc,
          builder: (context, visible) => visibilityButton(
              visible ? Icons.visibility_off : Icons.visibility, () => pinVisibilityBloc.add(!visible)),
        );

    final instruction = Text(
      instructionKey != null ? FlutterI18n.translate(context, instructionKey!) : this.instruction!,
      style: theme.textTheme.headline3?.copyWith(fontWeight: FontWeight.w700),
    );

    final pinDots = BlocConsumer<PinStateBloc, PinState>(
      bloc: pinBloc,
      listener: listener ?? (c, p) {},
      builder: (context, state) =>
          _PinIndicator(maxPinSize: maxPinSize, visibilityBloc: pinVisibilityBloc, pinState: state),
    );

    final pinDotsDecorated = Stack(
      fit: StackFit.passthrough,
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
            child: pinVisibility(pinVisibilityBloc),
          ),
        ),
      ],
    );

    final togglePinSizeCopy =
        maxPinSize > shortPinSize ? 'change_pin.choose_pin.switch_short' : 'change_pin.choose_pin.switch_long';

    final nextButton = BlocBuilder<PinStateBloc, PinState>(
      bloc: pinBloc,
      builder: (context, state) => activateNext(state.pin.length >= (shortPinSize == maxPinSize ? 5 : 6)),
    );

    final logo = SvgPicture.asset(
      'assets/non-free/logo_no_margin.svg',
      width: 127.scale(context),
      height: 71.scale(context),
      semanticsLabel: FlutterI18n.translate(
        context,
        'accessibility.irma_logo',
      ),
    );

    /// Only call when required
    List<Widget> bodyPortrait() => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                logo,
                instruction,
                pinDotsDecorated,
                if (checkSecurePin) _securePinTextButton(),
                if (onTogglePinSize != null)
                  Link(
                    onTap: onTogglePinSize,
                    label: FlutterI18n.translate(context, togglePinSizeCopy),
                  ),
                if (onForgotPin != null)
                  Link(
                    onTap: onForgotPin,
                    label: FlutterI18n.translate(context, 'pin.button_forgot'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _NumberPad(
              onEnterNumber: pinBloc.update,
            ),
          ),
          SizedBox(height: theme.screenPadding),
          nextButton,
        ];

    List<Widget> bodyLandscape() => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // logo, // TODO discuss with designer
                instruction,
                pinDotsDecorated,
                if (checkSecurePin) _securePinTextButton(),
                if (onTogglePinSize != null)
                  Link(
                    onTap: onTogglePinSize,
                    label: FlutterI18n.translate(context, togglePinSizeCopy),
                  ),
                if (onForgotPin != null)
                  Link(
                    onTap: onForgotPin,
                    label: FlutterI18n.translate(context, 'pin.button_forgot'),
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

    return OrientationBuilder(
      builder: (context, orientation) {
        if (Orientation.portrait == orientation) {
          return Column(
            children: bodyPortrait(),
          );
        } else {
          return Row(
            children: bodyLandscape(),
          );
        }
      },
    );
  }
}
