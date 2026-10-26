import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/translated_text.dart";

/// The Notifications tab before there is anything in it: three faded
/// notifications of the kinds that can come (a card that expires soon, has
/// expired, or was revoked) under a bell, "No notifications", and what they
/// are about.
class NoNotifications extends StatelessWidget {
  const NoNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      key: const Key("notifications_empty"),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          const ExcludeSemantics(child: _Picture()),
          const SizedBox(height: 28),
          TranslatedText(
            "notifications.empty",
            textAlign: TextAlign.center,
            style: palette.display(18).copyWith(color: palette.text),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TranslatedText(
              "notifications.empty_text",
              textAlign: TextAlign.center,
              style: palette
                  .body(14.5)
                  .copyWith(height: 21 / 14.5, color: palette.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three notifications in a stack, the back ones smaller and fainter, and a
/// bell on the corner of the front one.
class _Picture extends StatelessWidget {
  const _Picture();

  static const double _width = 232;
  static const double _row = 52;

  /// How much lower each notification is than the one behind it.
  static const double _step = 38;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    const kinds = [
      (Icons.block, DialogTone.danger),
      (Icons.warning_amber_rounded, DialogTone.warning),
      (Icons.schedule, DialogTone.info),
    ];
    return SizedBox(
      width: _width + 24,
      height: _row + 2 * _step + 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Back to front: each one lower and a little bigger, so all three
          // icons show.
          for (final (n, (icon, tone)) in kinds.indexed)
            Positioned(
              top: 22 + n * _step,
              child: Transform.scale(
                scale: 0.88 + n * 0.06,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: 0.55 + n * 0.225,
                  child: _Row(icon: icon, tone: tone, palette: palette),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                border: Border.all(color: palette.background, width: 3),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One notification, drawn as a sketch: its icon and two grey lines.
class _Row extends StatelessWidget {
  final IconData icon;
  final DialogTone tone;
  final YiviPalette palette;

  const _Row({required this.icon, required this.tone, required this.palette});

  @override
  Widget build(BuildContext context) {
    final bar = palette.secondaryText.withValues(alpha: 0.18);
    Widget line(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    return Container(
      width: _Picture._width,
      height: _Picture._row,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(YiviEdges.block(context)),
      ),
      child: Row(
        spacing: 12,
        children: [
          ToneDisc(icon: icon, tone: tone, size: 30, iconSize: 17),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [line(96, 8), line(140, 6)],
          ),
        ],
      ),
    );
  }
}
