import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// The two heights of the pill buttons: [large] at the bottom of a full
/// screen, [regular] in sheets, dialogs, button rows and content. A button
/// next to another one always has the same size.
enum PillSize {
  large(56),
  regular(52);

  final double height;

  const PillSize(this.height);

  /// The heights as constants, for layout that needs one.
  static const double largeHeight = 56;
  static const double regularHeight = 52;
}

/// The primary action: a pill in the faceted Yivi red (`ui/btn-bg.svg`, the
/// same art as today's fancy button), with a light top edge. No red glow
/// behind it: it stands on its own colour.
class FancyPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillSize size;
  final Widget? leading;
  final Widget? trailing;

  const FancyPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = PillSize.large,
    this.leading,
    this.trailing,
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
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: PressScale(
          child: DecoratedBox(
            decoration: const ShapeDecoration(shape: StadiumBorder()),
            child: ClipPath(
              clipper: const ShapeBorderClipper(shape: StadiumBorder()),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        yiviAsset("ui/btn-bg.svg"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
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
                          minWidth: double.infinity,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
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
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                              ?trailing,
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
      ),
    );
  }
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
    final (Color fill, Color fg, BorderSide side) = switch (style) {
      PillStyle.outlined when onDark => (
        Colors.white.withValues(alpha: 0.08),
        Colors.white,
        BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
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
        child: Material(
          color: fill,
          shape: StadiumBorder(side: side),
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

enum SmallPillTone {
  tint,
  primary,
  warning,
  surface,

  /// White with red text, on a red banner.
  onDanger,
}

/// A small action inside content: "Change", "Add", "Add a new …", "Why?".
/// 32 high and at least 44 wide, Open Sans 13 semibold. It takes no more
/// room than it shows, so a card header does not grow for it; the card or
/// row around it is usually the larger target.
class SmallPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SmallPillTone tone;
  final IconData? icon;

  const SmallPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SmallPillTone.tint,
    this.icon,
  });

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (Color fill, Color fg) = switch (tone) {
      SmallPillTone.tint => (palette.tint, palette.link),
      SmallPillTone.primary => (palette.primary, Colors.white),
      SmallPillTone.warning => (palette.warningSurface, palette.warningText),
      SmallPillTone.surface => (palette.surface, palette.link),
      SmallPillTone.onDanger => (Colors.white, palette.dangerFill),
    };
    final pill = Material(
      color: fill,
      shape: const StadiumBorder(),
      elevation: tone == SmallPillTone.surface ? 1 : 0,
      shadowColor: const Color(0x29000000),
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
              padding: EdgeInsets.fromLTRB(icon == null ? 14 : 10, 4, 14, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: fg),
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
    return Semantics(button: true, enabled: onPressed != null, child: pill);
  }
}

/// A text action: "Send again", "Show details", "Back to the website".
/// Open Sans 15 semibold in the link colour, no underline; [underline] only
/// for a link inside running text. The touch target is 44 high.
class TextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool underline;

  /// For a dark picture such as the camera.
  final Color? color;
  final TextAlign textAlign;

  const TextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.underline = false,
    this.color,
    this.textAlign = TextAlign.center,
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
                  textAlign: textAlign,
                  style: palette
                      .body(15, weight: FontWeight.w600)
                      .copyWith(
                        color: fg,
                        decoration: underline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: fg,
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

  /// Overrides the icon colour, e.g. for a filled star.
  final Color? color;

  const PlainIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.danger = false,
    this.iconSize = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      excludeSemantics: true,
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
              color:
                  color ??
                  (danger ? palette.danger : palette.heading).withValues(
                    alpha: onPressed == null ? 0.4 : 1,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
