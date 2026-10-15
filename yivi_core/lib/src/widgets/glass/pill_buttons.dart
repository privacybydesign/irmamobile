import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// The primary action: a pill in the faceted Yivi red (`ui/btn-bg.svg`, the
/// same art as today's fancy button), with a light top edge and a red glow.
class FancyPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Widget? leading;
  final bool glow;

  const FancyPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.leading,
    this.glow = true,
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
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              shadows: glow && enabled
                  ? const [
                      BoxShadow(
                        color: Color(0x59E12747),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
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
                      onTap: onPressed,
                      // [height] is the least: a label that wraps at a
                      // large text size makes the pill taller.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: height,
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

/// Secondary pill buttons: outlined, plain text, a filled neutral one ("Log
/// out"), a red text one for destructive actions and a red filled one that
/// confirms a destructive action in a dialog.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final double height;
  final Widget? leading;
  final bool expand;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.outlined,
    this.height = 52,
    this.leading,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (Color fill, Color fg, BorderSide side) = switch (style) {
      PillStyle.outlined => (
        palette.surface,
        palette.heading,
        BorderSide(color: palette.heading),
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

    // [height] is the least: a label that wraps at a large text size makes
    // the pill taller.
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
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
          child: InkWell(onTap: onPressed, child: content),
        ),
      ),
    );
  }
}
