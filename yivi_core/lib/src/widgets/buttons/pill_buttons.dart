import "dart:math" as math;

import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/text_fit.dart";
import "../surfaces/count_badge.dart";
import "press_scale.dart";

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
class PrimaryPillButton extends StatelessWidget {
  /// The shape of every big text button: the corners of a card.
  static const shape = RoundedRectangleBorder(
    borderRadius: YiviCorners.cardRadius,
  );

  /// How long the red takes to come in (and go) when the button becomes
  /// pressable (or stops being so).
  static const enableFade = YiviMotion.quick;

  final String label;
  final VoidCallback? onPressed;
  final PillSize size;
  final Widget? leading;

  /// Shown instead of [label] when that does not fit on one line (a label
  /// that names a card falls back to a generic one). Screen readers still
  /// hear [label].
  final String? shortLabel;

  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = PillSize.large,
    this.leading,
    this.shortLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final enabled = onPressed != null;
    final bar = size == PillSize.bar;
    final style = palette
        .display(bar ? 15 : 16, weight: FontWeight.w700)
        .copyWith(color: enabled ? Colors.white : palette.secondaryText);
    Widget textOf(String shown) => AnimatedDefaultTextStyle(
      duration: enableFade,
      curve: Curves.easeOut,
      style: style,
      child: Text(
        shown,
        textAlign: TextAlign.center,
        maxLines: bar ? 1 : null,
        overflow: bar ? TextOverflow.ellipsis : null,
      ),
    );
    final text = shortLabel == null
        ? textOf(label)
        : LayoutBuilder(
            builder: (context, constraints) => textOf(
              labelThatFits(
                context,
                full: label,
                short: shortLabel,
                style: style,
                width: constraints.maxWidth,
              ),
            ),
          );
    return _Tap(
      onTap: onPressed,
      label: label,
      dimWhenDisabled: false,
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
                      mainAxisSize: bar ? MainAxisSize.min : MainAxisSize.max,
                      spacing: YiviSpace.x8,
                      children: [
                        ?leading,
                        Flexible(child: text),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The primary action as a round button: [PrimaryPillButton]'s faceted red
/// (`ui/round-btn-bg.svg`) and light top edge, with a white [icon], and
/// on the same neutral fill when [onPressed] is null. The QR button,
/// the PIN's submit arrow, the manual entry of the document camera.
class PrimaryRoundButton extends StatelessWidget {
  final IconData icon;
  final double size;

  /// Null: about half of [size].
  final double? iconSize;
  final VoidCallback? onPressed;
  final String label;

  /// Under the button, e.g. to stand off the cards scrolling behind it.
  final List<BoxShadow>? shadows;

  const PrimaryRoundButton({
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
    return _Tap(
      onTap: onPressed,
      label: label,
      scale: PressScale.button,
      dimWhenDisabled: false,
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
                    duration: PrimaryPillButton.enableFade,
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
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        end: enabled ? Colors.white : palette.secondaryText,
                      ),
                      duration: PrimaryPillButton.enableFade,
                      curve: Curves.easeOut,
                      builder: (context, color, _) => Icon(
                        icon,
                        color: color,
                        size: iconSize ?? size * 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The faint rim of [PrimaryRoundButton] and the light edge along its top,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: YiviSpace.x8,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: YiviSpace.x8,
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

    return _Tap(
      onTap: onPressed,
      label: label,
      child: Material(
        color: fill,
        shape: PrimaryPillButton.shape.copyWith(side: side),
        clipBehavior: Clip.antiAlias,
        child: content,
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
      child: // Its own size, centred; a large text size makes it taller.
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height, minWidth: 44),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              YiviSpace.x4,
              14,
              YiviSpace.x4,
            ),
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
    );
    return _Tap(onTap: onPressed, label: label, child: pill);
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
    return _Tap(
      onTap: onPressed,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x8),
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
    );
  }
}

/// How a [YiviIconButton] looks.
enum IconButtonLook {
  /// In a bar: a 28 icon in the text colour, bare on what is behind it, as
  /// iOS's round bar buttons. With a count (filters on) a tinted disc and a
  /// badge.
  bar,

  /// In content: delete on a row, "more", copy, the × that removes an
  /// optional card. A 22 icon in the heading colour (red for danger).
  content,

  /// Over a camera picture or a photo: a dark disc with a white icon.
  dark,
}

/// The app's icon button, 44 across, in three looks ([IconButtonLook]). It
/// gives way a little under the finger.
class YiviIconButton extends StatelessWidget {
  static const double size = 44;

  /// The icon's box in a bar. Callers pass CupertinoIcons there: thin
  /// strokes, as SF Symbols.
  static const double barIconSize = 28;

  /// How much larger a + is drawn as it turns 45° into a close button: then
  /// it is as large as the ✕ (measured: the ✕ is 29% larger than the +
  /// turned, and a little bolder).
  static const double plusAsClose = 1.29;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final IconButtonLook look;

  /// Red, for a destructive action ([IconButtonLook.content]).
  final bool danger;

  /// The icon's colour instead of the look's (white over a photo's band).
  final Color? iconColor;

  /// The icon's size instead of the look's.
  final double? iconSize;

  /// Fades the button with what it sits on (a page's chrome).
  final double opacity;

  /// How many filters are on; 0 for none, or a button that has none.
  final int count;

  const YiviIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.look = IconButtonLook.content,
    this.danger = false,
    this.iconColor,
    this.iconSize,
    this.opacity = 1,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final on = count > 0;
    final a = opacity.clamp(0.0, 1.0);
    final (Color fill, Color ink, BorderSide edge) = switch (look) {
      IconButtonLook.dark => (
        Colors.black.withValues(alpha: 0.5),
        Colors.white,
        BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      _ when on => (
        palette.primary.withValues(alpha: palette.isDark ? 0.22 : 0.12),
        palette.selectedTab,
        BorderSide.none,
      ),
      IconButtonLook.bar => (
        Colors.transparent,
        iconColor ?? palette.text,
        BorderSide.none,
      ),
      IconButtonLook.content => (
        Colors.transparent,
        iconColor ?? (danger ? palette.danger : palette.heading),
        BorderSide.none,
      ),
    };
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            color: fill,
            shape: CircleBorder(side: edge),
          ),
          child: Icon(
            icon,
            size:
                iconSize ?? (look == IconButtonLook.content ? 22 : barIconSize),
            color: ink,
          ),
        ),
        if (on)
          Positioned(
            top: -4,
            right: -4,
            child: CountBadge(
              count: count,
              fill: palette.primary,
              ink: Colors.white,
              size: 20,
              fontSize: 11.5,
              ring: palette.background,
              plus: false,
              lineHeight: null,
            ),
          ),
      ],
    );
    return IgnorePointer(
      ignoring: a == 0,
      child: Opacity(
        opacity: a,
        child: _Tap(
          onTap: onTap,
          label: label,
          // In a bar the button stays as it is; in content it dims.
          dimWhenDisabled: look == IconButtonLook.content,
          child: button,
        ),
      ),
    );
  }
}

/// What every button here does with a tap: a button for screen readers
/// (named [label] when given), a press scale, a plain tap without ink, and
/// at half strength when it cannot be pressed ([dimWhenDisabled]).
class _Tap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final double scale;
  final bool dimWhenDisabled;

  const _Tap({
    required this.child,
    required this.onTap,
    this.label,
    this.scale = PressScale.button,
    this.dimWhenDisabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Widget tap = PressScale(
      scale: scale,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
    if (dimWhenDisabled && !enabled) tap = Opacity(opacity: 0.5, child: tap);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: label != null,
      child: tap,
    );
  }
}
