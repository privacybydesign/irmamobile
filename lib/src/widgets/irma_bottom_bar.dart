import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/irma_tooltip.dart';

class IrmaBottomBar extends StatelessWidget {
  const IrmaBottomBar({
    Key key,
    @required this.primaryButtonLabel,
    this.primaryButtonColor,
    this.onPrimaryPressed,
    this.onPrimaryDisabledPressed,
    this.showTooltipOnPrimary = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.toolTipLabel,
  })  : assert((showTooltipOnPrimary == false) || (toolTipLabel != null)),
        assert(primaryButtonLabel != null),
        super(key: key);

  final String primaryButtonLabel;
  final Color primaryButtonColor;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onPrimaryDisabledPressed;
  final bool showTooltipOnPrimary;
  final String secondaryButtonLabel;
  final VoidCallback onSecondaryPressed;
  final String toolTipLabel;

  List<Widget> buildButtons(BuildContext context, BoxConstraints constraints) {
    final List<Widget> btns = [];

    double buttonWidth = constraints.maxWidth - 2 * IrmaTheme.of(context).defaultSpacing;
    if (secondaryButtonLabel != null) {
      buttonWidth = constraints.maxWidth / 2 - 2 * IrmaTheme.of(context).defaultSpacing;

      btns.add(IrmaTextButton(
        size: IrmaButtonSize.large,
        minWidth: buttonWidth,
        onPressed: onSecondaryPressed,
        label: secondaryButtonLabel,
      ));
    }

    Widget primaryButton = IrmaButton(
      size: IrmaButtonSize.large,
      minWidth: buttonWidth,
      onPressed: onPrimaryPressed,
      onPressedDisabled: onPrimaryDisabledPressed,
      label: primaryButtonLabel,
      color: primaryButtonColor,
    );

    if (toolTipLabel != null) {
      primaryButton = IrmaTooltip(
          label: FlutterI18n.translate(context, toolTipLabel), show: showTooltipOnPrimary, child: primaryButton);
    }

    btns.add(primaryButton);

    return btns;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: IrmaTheme.of(context).backgroundBlue,
          border: Border(
            top: BorderSide(
              color: IrmaTheme.of(context).primaryLight,
              width: 2.0,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: IrmaTheme.of(context).mediumSpacing, horizontal: IrmaTheme.of(context).defaultSpacing),
          child: Wrap(
            direction: Axis.horizontal,
            verticalDirection: VerticalDirection.up,
            alignment: WrapAlignment.center,
            children: buildButtons(context, constraints),
          ),
        ),
      );
    });
  }
}
