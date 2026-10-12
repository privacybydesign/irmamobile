import "package:material_ui/material_ui.dart";

/// The underline border of a form fields V2 field. It casts [shadow] around
/// the field only, since an `InputDecorator` draws its message outside of the
/// border, where a shadow from a widget around the field would reach too.
class YiviFieldBorder extends UnderlineInputBorder {
  final BoxShadow shadow;

  const YiviFieldBorder({
    required this.shadow,
    super.borderSide,
    super.borderRadius,
  });

  @override
  YiviFieldBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    BoxShadow? shadow,
  }) {
    return YiviFieldBorder(
      shadow: shadow ?? this.shadow,
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  YiviFieldBorder scale(double t) {
    return YiviFieldBorder(
      shadow: shadow.scale(t),
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is! YiviFieldBorder) return super.lerpFrom(a, t);

    return YiviFieldBorder(
      shadow: BoxShadow.lerp(a.shadow, shadow, t)!,
      borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
    );
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is! YiviFieldBorder) return super.lerpTo(b, t);

    return YiviFieldBorder(
      shadow: BoxShadow.lerp(shadow, b.shadow, t)!,
      borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    // The fill is already painted, so the shadow is clipped to what is outside
    // the field instead of showing through it.
    final outer = getOuterPath(rect, textDirection: textDirection);
    final reach = shadow.blurRadius * 3 + shadow.offset.distance;
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(reach)),
      outer,
    );

    canvas.save();
    canvas.clipPath(outside);
    canvas.drawPath(outer.shift(shadow.offset), shadow.toPaint());
    canvas.restore();

    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    return super == other && other is YiviFieldBorder && other.shadow == shadow;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, shadow);
}
