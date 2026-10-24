import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/laid_out_box.dart";
import "glass/glass_surface.dart";

/// Where the top bar's buttons end, from the top of the safe area: 16 above
/// the 44 pt buttons of an `IrmaAppBar`, and the buttons.
const double _barButtonsBottom = 16 + 44;

/// Whether the bottom of the header at [headerKey] has scrolled up under
/// the top bar; null while the header is not laid out. Measured from the
/// header itself, not a fixed offset: it grows when a long name wraps.
bool? headerUnderBar(BuildContext context, GlobalKey headerKey) {
  final box = headerKey.currentContext.laidOutBox;
  if (box == null) return null;
  final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
  return bottom < MediaQuery.paddingOf(context).top + _barButtonsBottom;
}

/// The compact bar of a detail page while [shown] (the header has scrolled
/// under the top bar): it drops in from just above and fades in. [bar] gets
/// how far it is in, from 0 to 1, for its opacity.
class CompactBarDropIn extends StatelessWidget {
  final ValueListenable<bool> shown;
  final Widget Function(double t) bar;

  const CompactBarDropIn({super.key, required this.shown, required this.bar});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: shown,
    builder: (context, on, _) => TweenAnimationBuilder<double>(
      tween: Tween(end: on ? 1 : 0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      builder: (context, t, _) => t == 0
          ? const SizedBox.shrink()
          : IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -8),
                child: bar(t),
              ),
            ),
    ),
  );
}

/// The glass pill in the top bar of a detail page that says what the page
/// is about once its header has scrolled away: a 32 pt [leading] picture,
/// the [title] and a [subtitle] line, each on one line.
class GlassCompactBar extends StatelessWidget {
  final Widget leading;
  final String title;
  final InlineSpan subtitle;
  final double opacity;

  const GlassCompactBar({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassSurface(
      opacity: opacity,
      padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          spacing: 8,
          children: [
            leading,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.display(14).copyWith(color: palette.text),
                  ),
                  Text.rich(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .body(12)
                        .copyWith(color: palette.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
