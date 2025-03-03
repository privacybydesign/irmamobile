library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';
import '../../util/haptics.dart';
import '../../util/scale.dart';
import '../../util/tablet.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/link.dart';
import '../../widgets/yivi_bottom_sheet.dart';
import '../../widgets/yivi_themed_button.dart';

part 'bloc/enter_pin_state.dart';
part 'number_pad.dart';
part 'number_pad_icon.dart';
part 'number_pad_key.dart';
part 'pin_indicator.dart';
part 'scalable_text.dart';
part 'secure_pin.dart';
part 'unsecure_pin_description_tile.dart';
part 'unsecure_pin_full_screen.dart';
part 'unsecure_pin_list_builder.dart';
part 'unsecure_pin_warning_text_button.dart';
part 'yivi_pin_scaffold.dart';

enum WidgetVisibility { invisible, visible, gone }

typedef PinQuality = Set<SecurePinAttribute>;
typedef NumberCallback = void Function(int);
typedef StringCallback = void Function(String);

const _nextButtonHeight = 48.0;

const shortPinSize = 5;
const longPinSize = 16;

WidgetVisibility defaultSubmitButtonVisibility(BuildContext context, int maxPinSize) {
  if (maxPinSize == longPinSize) {
    return WidgetVisibility.visible;
  }

  if ((Orientation.landscape == MediaQuery.of(context).orientation)) {
    return WidgetVisibility.gone;
  } else {
    return WidgetVisibility.invisible;
  }
}

class YiviPinScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int maxPinSize;
  final StringCallback onSubmit;
  final EnterPinStateBloc pinBloc;
  final pinVisibilityValue = ValueNotifier(false);
  final VoidCallback? onForgotPin;
  final VoidCallback? onTogglePinSize;
  final bool displayPinLength;
  final bool checkSecurePin;
  final String? instructionKey;
  final String? instruction;
  final bool enabled;
  final void Function(BuildContext, EnterPinState)? listener;
  final WidgetVisibility Function(BuildContext, EnterPinState)? submitButtonVisibilityListener;

  YiviPinScreen({
    Key key = const Key('pin_screen'),
    this.scaffoldKey,
    this.instructionKey,
    this.instruction,
    required this.pinBloc,
    required this.maxPinSize,
    required this.onSubmit,
    this.onForgotPin,
    this.displayPinLength = false,
    this.onTogglePinSize,
    this.checkSecurePin = false,
    this.enabled = true,
    this.listener,
    this.submitButtonVisibilityListener,
  })  : assert(instructionKey != null && instruction == null || instruction != null && instructionKey == null),
        assert(checkSecurePin ? scaffoldKey != null : true),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return BlocConsumer<EnterPinStateBloc, EnterPinState>(
          bloc: pinBloc,
          listener: listener ?? (_, __) {},
          builder: (context, state) {
            final showSecurePinText = state.pin.length >= shortPinSize && !state.goodEnough;
            if (Orientation.portrait == orientation) {
              return _bodyPortrait(
                context,
                showSecurePinText: showSecurePinText,
              );
            } else {
              return bodyLandscape(
                context,
                showSecurePinText: showSecurePinText,
              );
            }
          },
        );
      },
    );
  }

  Row bodyLandscape(
    BuildContext context, {
    required bool showSecurePinText,
  }) {
    final leftColumnChildren = [
      _buildInstructionText(context),
      _buildDecoratedPinDots(context),
      if (checkSecurePin && showSecurePinText) _UnsecurePinWarningTextButton(scaffoldKey: scaffoldKey!, bloc: pinBloc),
      if (onTogglePinSize != null)
        Center(
          child: Link(
            onTap: onTogglePinSize!,
            label: FlutterI18n.translate(context, _getTogglePinSizeSemanticKey()),
          ),
        ),
      if (onForgotPin != null)
        Center(
          child: Link(
            onTap: onForgotPin!,
            label: FlutterI18n.translate(context, 'pin.button_forgot'),
          ),
        ),
      _buildNextButton(),
    ];

    final lt5Children = leftColumnChildren.length < 5;

    final separatedChildren = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lt5Children) _buildScaledLogo(context),
        ...leftColumnChildren,
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: separatedChildren,
                ),
              ),
            );
          }),
        ),
        Expanded(
          child: _NumberPad(
            onEnterNumber: pinBloc.add,
          ),
        ),
      ],
    );
  }

  Column _bodyPortrait(
    BuildContext context, {
    required bool showSecurePinText,
  }) {
    final theme = IrmaTheme.of(context);
    return Column(
      children: [
        SizedBox(height: theme.screenPadding),
        _buildNextButton(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildScaledLogo(context),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInstructionText(context),
                              _buildDecoratedPinDots(context),
                              if (checkSecurePin && showSecurePinText)
                                _UnsecurePinWarningTextButton(scaffoldKey: scaffoldKey!, bloc: pinBloc),
                              if (onTogglePinSize != null)
                                Link(
                                  onTap: onTogglePinSize!,
                                  label: FlutterI18n.translate(context, _getTogglePinSizeSemanticKey()),
                                ),
                              if (onForgotPin != null)
                                Link(
                                  onTap: onForgotPin!,
                                  label: FlutterI18n.translate(context, 'pin.button_forgot'),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _NumberPad(
            onEnterNumber: pinBloc.add,
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratedPinDots(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final pinDots = _buildPinDots();

    return Column(
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
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildListeningPinVisibilityButton(),
              ),
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
                  color: theme.secondary,
                ),
                if (displayPinLength)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: BlocBuilder<EnterPinStateBloc, EnterPinState>(
                      bloc: pinBloc,
                      builder: (context, state) => Text(
                        '${state.pin.length}/$maxPinSize',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: state.pin.isNotEmpty ? theme.secondary : Colors.transparent),
                      ),
                    ),
                  )
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPinDots() {
    return BlocBuilder<EnterPinStateBloc, EnterPinState>(
      bloc: pinBloc,
      builder: (context, state) {
        return _PinIndicator(maxPinSize: maxPinSize, pinVisibilityValue: pinVisibilityValue, pinState: state);
      },
    );
  }

  Widget _buildListeningPinVisibilityButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: pinVisibilityValue,
      builder: (context, visible, _) {
        return _buildPinVisibilityButton(
          context,
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          'pin_accessibility.${visible ? 'hide' : 'show'}_pin',
          () => pinVisibilityValue.value = !visible,
        );
      },
    );
  }

  Widget _buildPinVisibilityButton(BuildContext context, IconData icon, String semanticLabelKey, VoidCallback fn) {
    final theme = IrmaTheme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: fn,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 24,
              color: theme.secondary,
              semanticLabel: FlutterI18n.translate(
                context,
                semanticLabelKey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivateNextButton(bool activate, WidgetVisibility visibility) {
    final button = SizedBox(
      height: _nextButtonHeight,
      child: YiviThemedButton(
        key: const Key('pin_next'),
        label: 'choose_pin.next',
        onPressed: activate && enabled ? () => onSubmit(pinBloc.state.toString()) : null,
      ),
    );

    switch (visibility) {
      case WidgetVisibility.gone:
        return Visibility(
          visible: false,
          child: button,
        );
      case WidgetVisibility.invisible:
        return Visibility(
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          visible: false,
          child: button,
        );
      case WidgetVisibility.visible:
        return button;
    }
  }

  Widget _buildNextButton() {
    return BlocBuilder<EnterPinStateBloc, EnterPinState>(
      bloc: pinBloc,
      builder: (context, state) {
        return _buildActivateNextButton(
          state.pin.length >= (shortPinSize == maxPinSize ? 5 : 6),
          submitButtonVisibilityListener?.call(context, state) ?? defaultSubmitButtonVisibility(context, maxPinSize),
        );
      },
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Semantics(
        header: true,
        child: Text(
          instruction ?? FlutterI18n.translate(context, instructionKey!),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall,
        ),
      ),
    );
  }

  Widget _buildScaledLogo(BuildContext context) {
    // It's harder to define a fractional height in relation to the
    // screen size, due to variable nature of phone devices, hence
    // the scaling here
    return SvgPicture.asset(
      'assets/non-free/logo_no_margin.svg',
      width: 127.scaleToDesignSize(context),
      height: 71.scaleToDesignSize(context),
      semanticsLabel: FlutterI18n.translate(
        context,
        'accessibility.irma_logo',
      ),
    );
  }

  String _getTogglePinSizeSemanticKey() {
    return 'choose_pin.switch_pin_size.${maxPinSize > shortPinSize ? 'short' : 'long'}';
  }
}
