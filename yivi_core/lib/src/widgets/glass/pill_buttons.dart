import "dart:math" as math;

import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../press_scale.dart";

/// The two heights of the pill buttons: [large] at the bottom of a full
/// screen, [regular] in sheets, dialogs, button rows and content. A button
/// next to another one always has the same size.
enum PillSize {
  large(PillSize.largeHeight),
  regular(PillSize.regularHeight),

  /// The way on in the bar of a sheet (see `SheetBarButton`): a capsule as
  /// wide as its label.
  bar(36);

  final double height;

  const PillSize(this.height);

  /// The heights as constants, for layout that needs one.
  static const double largeHeight = 56;
  static const double regularHeight = 52;
}

/// The primary action: a rounded rectangle in the faceted Yivi red
/// (`ui/btn-bg.svg`, the same art as today's fancy button), with a light top
/// edge. No red glow behind it: it stands on its own colour.
class FancyPillButton extends StatelessWidget {
  /// The shape of every big text button: the corners of a card.
  static const shape = RoundedRectangleBorder(
    borderRadius: YiviCorners.cardRadius,
  );

  /// How long the red takes to come in (and go) when the button becomes
  /// pressable (or stops being so).
  static const enableFade = Duration(milliseconds: 200);

  final String label;
  final VoidCallback? onPressed;
  final PillSize size;
  final Widget? leading;

  const FancyPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = PillSize.large,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final enabled = onPressed != null;
    final bar = size == PillSize.bar;
    final text = AnimatedDefaultTextStyle(
      duration: enableFade,
      curve: Curves.easeOut,
      style: palette
          .display(bar ? 15 : 16, weight: FontWeight.w700)
          .copyWith(color: enabled ? Colors.white : palette.secondaryText),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: bar ? 1 : null,
        overflow: bar ? TextOverflow.ellipsis : null,
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        enabled: enabled,
        // Not pressable yet: a plain neutral fill, without the red and its
        // facets, so it reads as waiting rather than as a faded red button.
        // Solid rather than see-through: it covers the button it replaces
        // while sheet pages change. The red fades in when it can be pressed.
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: shape),
          child: ColoredBox(
            color: palette.disabledFill,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: AnimatedOpacity(
                      opacity: enabled ? 1 : 0,
                      duration: enableFade,
                      curve: Curves.easeOut,
                      child: SvgPicture.asset(
                        yiviAsset("ui/btn-bg.svg"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    // Dark: flat, no line across the top. Disabled: none.
                    child: palette.isDark || !enabled
                        ? null
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.28),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    onTap: onPressed,
                    // The size's height is the least: a label that wraps at a
                    // large text size makes the pill taller.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: size.height,
                        minWidth: bar ? 0 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: bar ? 16 : 20,
                          vertical: bar ? 0 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: bar
                              ? MainAxisSize.min
                              : MainAxisSize.max,
                          spacing: 8,
                          children: [
                            ?leading,
                            Flexible(child: text),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary action as a round button: [FancyPillButton]'s faceted red
/// (`ui/round-btn-bg.svg`) and light top edge, with a white [icon], and
/// on the same neutral fill when [onPressed] is null. The QR button,
/// the PIN's submit arrow, the manual entry of the document camera.
class FancyRoundButton extends StatelessWidget {
  final IconData icon;
  final double size;

  /// Null: about half of [size].
  final double? iconSize;
  final VoidCallback? onPressed;
  final String label;

  /// Under the button, e.g. to stand off the cards scrolling behind it.
  final List<BoxShadow>? shadows;

  const FancyRoundButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.label,
    this.iconSize,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.button,
        enabled: enabled,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            shadows: shadows,
          ),
          position: DecorationPosition.background,
          child: ClipOval(
            child: ColoredBox(
              color: palette.disabledFill,
              child: SizedBox.square(
                dimension: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedOpacity(
                      opacity: enabled ? 1 : 0,
                      duration: FancyPillButton.enableFade,
                      curve: Curves.easeOut,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SvgPicture.asset(
                            yiviAsset("ui/round-btn-bg.svg"),
                            fit: BoxFit.cover,
                          ),
                          const IgnorePointer(
                            child: CustomPaint(painter: _RoundEdgePainter()),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        highlightColor: Colors.transparent,
                        customBorder: const CircleBorder(),
                        onTap: onPressed,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                            end: enabled ? Colors.white : palette.secondaryText,
                          ),
                          duration: FancyPillButton.enableFade,
                          curve: Curves.easeOut,
                          builder: (context, color, _) => Icon(
                            icon,
                            color: color,
                            size: iconSize ?? size * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The faint rim of [FancyRoundButton] and the light edge along its top,
/// which fades out towards the sides: the light edge of the red pills.
class _RoundEdgePainter extends CustomPainter {
  const _RoundEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawArc(
      rect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = SweepGradient(
          startAngle: math.pi * 1.15,
          endAngle: math.pi * 1.85,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RoundEdgePainter old) => false;
}

enum PillStyle { outlined, text, neutral, danger, dangerFilled }

/// Secondary pill buttons:
/// - [PillStyle.outlined]: a secondary action on its own.
/// - [PillStyle.text]: Cancel, back out or "not now", next to a primary.
/// - [PillStyle.neutral]: a filled neutral action ("Log out", "Reobtain").
/// - [PillStyle.danger]: red text that starts a destructive action.
/// - [PillStyle.dangerFilled]: red, confirms a destructive action.
///
/// Next to another button it takes that button's [size].
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final PillSize size;
  final Widget? leading;
  final bool expand;

  /// On a dark picture such as the camera: white text and outline.
  final bool onDark;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.outlined,
    this.size = PillSize.regular,
    this.leading,
    this.expand = true,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // Dark theme: a flat pill in the surface colour, as a light outline there
    // looked cheap. High contrast keeps the outline.
    final flat =
        style == PillStyle.outlined &&
        !onDark &&
        palette.isDark &&
        !MediaQuery.highContrastOf(context);
    final (Color fill, Color fg, BorderSide side) = switch (style) {
      PillStyle.outlined when onDark => (
        Colors.white.withValues(alpha: 0.08),
        Colors.white,
        BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
      ),
      PillStyle.outlined when flat => (
        // Solid, a level above the page or sheet.
        palette.surface,
        palette.text,
        BorderSide.none,
      ),
      PillStyle.outlined => (
        palette.surface,
        palette.heading,
        BorderSide(color: palette.heading, width: 1.5),
      ),
      PillStyle.text when onDark => (
        Colors.transparent,
        Colors.white,
        BorderSide.none,
      ),
      PillStyle.text => (Colors.transparent, palette.heading, BorderSide.none),
      PillStyle.neutral => (palette.heading, palette.surface, BorderSide.none),
      PillStyle.danger => (Colors.transparent, palette.danger, BorderSide.none),
      PillStyle.dangerFilled => (
        palette.dangerFill,
        Colors.white,
        BorderSide.none,
      ),
    };

    // The size's height is the least: a label that wraps at a large text
    // size makes the pill taller.
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: size.height,
        minWidth: expand ? double.infinity : 0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            ?leading,
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: palette
                    .display(16, weight: FontWeight.w700)
                    .copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: PressScale(
        enabled: onPressed != null,
        child: Material(
          color: fill,
          shape: FancyPillButton.shape.copyWith(side: side),
          clipBehavior: Clip.antiAlias,
          // No ink: the pill gives feedback by scaling, like the other glass
          // buttons.
          child: InkWell(
            onTap: onPressed,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: content,
          ),
        ),
      ),
    );
  }
}

enum SmallPillTone { tint, primary }

/// A small action inside content: "Change", "Add", "Add a new …", "Why?".
/// 32 high and at least 44 wide, Open Sans 13 semibold. It takes no more
/// room than it shows, so a card header does not grow for it; the card or
/// row around it is usually the larger target.
class SmallPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SmallPillTone tone;

  const SmallPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SmallPillTone.tint,
  });

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (Color fill, Color fg) = switch (tone) {
      SmallPillTone.tint => (palette.tint, palette.link),
      SmallPillTone.primary => (palette.primary, Colors.white),
    };
    final pill = Material(
      color: fill,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        highlightColor: Colors.transparent,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height, minWidth: 44),
          // Its own size, centred; a large text size makes it taller.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: palette
                          .body(13, weight: FontWeight.w600)
                          .copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: PressScale(enabled: onPressed != null, child: pill),
    );
  }
}

/// A text action: "Send again", "Show details", "Back to the website".
/// Open Sans 15 semibold in the link colour, no underline. The touch target
/// is 44 high.
class TextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// For a dark picture such as the camera.
  final Color? color;

  const TextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final fg = color ?? palette.link;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: PressScale(
          enabled: onPressed != null,
          child: InkWell(
            highlightColor: Colors.transparent,
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: palette
                        .body(15, weight: FontWeight.w600)
                        .copyWith(
                          color: fg,
                          decoration: TextDecoration.none,
                          decorationColor: fg,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bare icon in content: delete on a row, "more", favourite, copy, the ×
/// that removes an optional card. Icon 22 in the heading colour (or red for
/// [danger]); the touch target is 44.
class PlainIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticsLabel;
  final bool danger;
  final double iconSize;

  const PlainIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.danger = false,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: PressScale(
        enabled: onPressed != null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            highlightColor: Colors.transparent,
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                icon,
                size: iconSize,
                color: (danger ? palette.danger : palette.heading).withValues(
                  alpha: onPressed == null ? 0.4 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
