import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class IrmaStickyBottomBarScaffold extends StatelessWidget {

  IrmaStickyBottomBarScaffold({
    Key key,
    @required this.appBar,
    @required this.body,
    @required this.primaryBtnLabel,
    @required this.onPrimaryPressed,
    this.disabled = false,
    this.tooltipOnPrimaryBtn = false,
    this.secondaryBtnLabel,
    this.onSecondaryPressed,
    this.toolTipLabel,
  })
    : assert((secondaryBtnLabel == null) == (onSecondaryPressed == null))
    , assert((tooltipOnPrimaryBtn == true) == (toolTipLabel != null))
    , assert(appBar != null)
    , assert(body != null)
    , assert(primaryBtnLabel != null)
    , super(key: key);

  final Widget body;
  final PreferredSizeWidget appBar;
  final String primaryBtnLabel;
  final VoidCallback onPrimaryPressed;
  final bool disabled;
  final bool tooltipOnPrimaryBtn;
  final String secondaryBtnLabel;
  final VoidCallback onSecondaryPressed;
  final String toolTipLabel;

  List<Widget> buildBtns(BuildContext context) {
    final List<Widget> btns = [];

    final int btnAlpha = disabled ? 127 : 255;

    if (secondaryBtnLabel != null)
    {
      btns.add(IrmaTextButton(
        alpha: btnAlpha,
        onPressed: onSecondaryPressed,
        minWidth: 0.0,
        label: secondaryBtnLabel,
      ));
    }

    final primaryBtn = IrmaButton(
      size: IrmaButtonSize.small,
      alpha: btnAlpha,
      minWidth: 0.0,
      onPressed: onPrimaryPressed,
      label: primaryBtnLabel,
    );

    btns.add(primaryBtn);

    return btns;
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: Container(
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
          padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
          child: Wrap(
            direction: Axis.horizontal,
            verticalDirection: VerticalDirection.up,
            alignment: WrapAlignment.spaceEvenly,
            children: buildBtns(context),
          ),
        ),
      ),
    );
  }
}