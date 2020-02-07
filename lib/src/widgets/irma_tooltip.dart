import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/programmable_tooltip.dart';

class IrmaToolTip extends StatelessWidget {
  const IrmaToolTip({
    Key key,
    @required this.label,
    @required this.child,
    @required this.show,
  })  : assert(label != null),
        assert(child != null),
        super(key: key);

  final String label;
  final Widget child;
  final bool show;

  @override
  Widget build(BuildContext context) {
    return ProgrammableTooltip(
      decoration: ShapeDecoration(
          color: IrmaTheme.of(context).primaryLight,
          shape: const _TooltipShapeBorder(),
          shadows: [BoxShadow(color: Colors.black54, blurRadius: 0.8, offset: const Offset(0, 1))]),
      padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).mediumSpacing, vertical: IrmaTheme.of(context).smallSpacing),
      margin: EdgeInsets.only(bottom: IrmaTheme.of(context).smallSpacing),
      textStyle: IrmaTheme.of(context).textTheme.display1,
      message: FlutterI18n.translate(context, label),
      show: show,
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
    this.radius = 6.0,
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
