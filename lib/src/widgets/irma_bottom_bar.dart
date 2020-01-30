import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class IrmaBottomBar extends StatelessWidget {
  const IrmaBottomBar({
    Key key,
    @required this.primaryButtonLabel,
    this.onPrimaryPressed,
    this.onPrimaryDisabledPressed,
    this.tooltipOnPrimaryButton = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.toolTipLabel,
  })  : assert((tooltipOnPrimaryButton == true) == (toolTipLabel != null)),
        assert(primaryButtonLabel != null),
        super(key: key);

  final String primaryButtonLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onPrimaryDisabledPressed;
  final bool tooltipOnPrimaryButton;
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

    Widget primaryButtonn = IrmaButton(
      size: IrmaButtonSize.large,
      minWidth: buttonWidth,
      onPressed: onPrimaryPressed,
      onPressedDisabled: onPrimaryDisabledPressed,
      label: primaryButtonLabel,
    );

    if (tooltipOnPrimaryButton) {
      primaryButtonn = _IrmaToolTip(
        label: FlutterI18n.translate(context, toolTipLabel),
        child: primaryButtonn,
      );
    }

    btns.add(primaryButtonn);

    return btns;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
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

class _IrmaToolTip extends StatelessWidget {
  const _IrmaToolTip({
    Key key,
    @required this.label,
    @required this.child,
  })  : assert(label != null),
        assert(child != null),
        super(key: key);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      decoration: ShapeDecoration(
          color: IrmaTheme.of(context).primaryLight,
          shape: const _TooltipShapeBorder(),
          shadows: [BoxShadow(color: Colors.black54, blurRadius: 0.8, offset: const Offset(0, 1))]),
      padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).mediumSpacing, vertical: IrmaTheme.of(context).smallSpacing),
      textStyle: IrmaTheme.of(context).textTheme.display1,
      message: FlutterI18n.translate(context, label),
      child: child,
    );
  }
}

class _TooltipShapeBorder extends ShapeBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double arrowArc;
  final double radius;

  const _TooltipShapeBorder({
    this.radius = 4.0,
    this.arrowWidth = 30.0,
    this.arrowHeight = 15.0,
    this.arrowArc = 0.0,
  }) : assert(arrowArc <= 1.0 && arrowArc >= 0.0);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: arrowHeight);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    final newRect = Rect.fromPoints(rect.topLeft, rect.bottomRight - Offset(0, arrowHeight));
    final double x = arrowWidth, y = arrowHeight, r = 1 - arrowArc;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(newRect, Radius.circular(radius)))
      ..moveTo(newRect.bottomCenter.dx + x / 2, newRect.bottomCenter.dy)
      ..relativeLineTo(-x / 2 * r, y * r)
      ..relativeLineTo(-x / 2 * r, -y * r);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
