library pin;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../..//util/tablet.dart';
import '../../theme/theme.dart';
import '../../util/scale.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/link.dart';
import '../../widgets/yivi_bottom_sheet.dart';

part 'bloc/enter_pin_state.dart';
part 'bloc/pin_visibility.dart';
part 'circle_clip.dart';
part 'number_pad.dart';
part 'number_pad_key.dart';
part 'pin_indicator.dart';
part 'secure_pin.dart';
part 'unsecure_pin_description_tile.dart';
part 'unsecure_pin_full_screen.dart';
part 'unsecure_pin_list_builder.dart';
part 'unsecure_pin_warning_text_button.dart';
part 'yivi_pin_scaffold.dart';

typedef Pin = List<int>;
typedef PinCallback = bool Function(Pin);
typedef PinQuality = Set<SecurePinAttribute>;
typedef NumberCallback = void Function(int);
typedef StringCallback = void Function(String);

const _nextButtonHeight = 48.0;

const shortPinSize = 5;
const longPinSize = 16;

Widget _resizeBox(Widget widget, double edge) => SizedBox(
      width: edge,
      height: edge,
      child: widget,
    );

class YiviPinScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int maxPinSize;
  final StringCallback onSubmit;
  final EnterPinStateBloc pinBloc;
  final PinVisibilityBloc pinVisibilityBloc;
  final VoidCallback? onForgotPin;
  final VoidCallback? onTogglePinSize;
  final bool checkSecurePin;
  final String? instructionKey;
  final String? instruction;
  final bool enabled;
  final void Function(BuildContext, EnterPinState, String)? listener;

  const YiviPinScreen({
    Key? key,
    this.scaffoldKey,
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
        assert(checkSecurePin ? scaffoldKey != null : true),
        super(key: key);

  /// Some functions are nested to save on ceremony for repeatedly passed parameters
  /// Also nested functions are not exposed outside the parent function
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget visibilityButton(IconData icon, VoidCallback fn) => ClipPath(
          clipper: _PerfectCircleClip(),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              width: 32,
              height: 32,
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
                else if (states.contains(MaterialState.disabled)) return theme.secondary.withOpacity(0.5);
                return theme.secondary;
              },
            ),
            minimumSize: MaterialStateProperty.resolveWith<Size>((s) => const Size.fromHeight(_nextButtonHeight)),
            shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
              (s) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          onPressed: activate && enabled ? () => onSubmit(pinBloc.state.pin.join()) : null,
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

    final pinDots = BlocBuilder<EnterPinStateBloc, EnterPinState>(
      bloc: pinBloc,
      builder: (context, state) =>
          _PinIndicator(maxPinSize: maxPinSize, visibilityBloc: pinVisibilityBloc, pinState: state),
    );

    final pinDotsDecorated = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            FractionallySizedBox(
              widthFactor: .72,
              child: pinDots,
            ),
            Align(
              alignment: Alignment.topRight,
              child: pinVisibility(pinVisibilityBloc),
            ),
          ],
        ),
        if (maxPinSize != shortPinSize)
          FractionallySizedBox(
            widthFactor: .72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Divider(
                  height: 1.0,
                  color: theme.darkPurple,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: BlocBuilder<EnterPinStateBloc, EnterPinState>(
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
      ],
    );

    final togglePinSizeCopy =
        maxPinSize > shortPinSize ? 'change_pin.choose_pin.switch_short' : 'change_pin.choose_pin.switch_long';

    final nextButton = BlocBuilder<EnterPinStateBloc, EnterPinState>(
      bloc: pinBloc,
      builder: (context, state) => activateNext(state.pin.length >= (shortPinSize == maxPinSize ? 5 : 6)),
    );

    /// It's harder to define a fractional height in relation to the
    /// screen size, due to variable nature of phone devices, hence
    /// the scaling here
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
    List<Widget> bodyPortrait(bool showSecurePinText) => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                logo,
                instruction,
                pinDotsDecorated,
                if (checkSecurePin && showSecurePinText)
                  _UnsecurePinWarningTextButton(scaffoldKey: scaffoldKey!, bloc: pinBloc),
                if (onTogglePinSize != null)
                  Link(
                    onTap: onTogglePinSize!,
                    label: FlutterI18n.translate(context, togglePinSizeCopy),
                  ),
                if (onForgotPin != null)
                  Link(
                    onTap: onForgotPin!,
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

    List<Widget> bodyLandscape(bool showSecurePinText) => [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // logo, // TODO discuss with designer
                instruction,
                pinDotsDecorated,
                if (checkSecurePin && showSecurePinText)
                  _UnsecurePinWarningTextButton(scaffoldKey: scaffoldKey!, bloc: pinBloc),
                if (onTogglePinSize != null)
                  Link(
                    onTap: onTogglePinSize!,
                    label: FlutterI18n.translate(context, togglePinSizeCopy),
                  ),
                if (onForgotPin != null)
                  Link(
                    onTap: onForgotPin!,
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
        return BlocConsumer<EnterPinStateBloc, EnterPinState>(
          bloc: pinBloc,
          listener: (context, state) => listener?.call(context, state, state.pin.join()),
          builder: (context, state) {
            final showSecurePinText =
                state.pin.length >= shortPinSize && !state.attributes.contains(SecurePinAttribute.goodEnough);
            if (Orientation.portrait == orientation) {
              return Column(
                children: bodyPortrait(showSecurePinText),
              );
            } else {
              return Row(
                children: bodyLandscape(showSecurePinText),
              );
            }
          },
        );
      },
    );
  }
}
