import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/test_detection.dart";
import "glass/glass_dialog.dart";

/// The middle of a status screen (an error, a warning, "update required"):
/// a large tinted disc with an icon or picture, a heading, a message, an
/// optional note and anything below that, centred and scrollable.
class StatusBody extends StatelessWidget {
  final String title;
  final String? message;

  /// Small grey text under the message, e.g. "If this happens again, …".
  final String? note;

  /// Shown in the disc; [picture] replaces the icon.
  final IconData? icon;
  final Widget? picture;
  final DialogTone tone;

  /// Overrides the icon colour that [tone] picks.
  final Color? iconColor;

  /// Overrides the disc colour that [tone] picks, e.g. white behind a logo.
  final Color? discColor;

  /// Shown under the note, e.g. a link or a technical details block.
  final Widget? footer;

  const StatusBody({
    super.key,
    required this.title,
    this.message,
    this.note,
    this.icon,
    this.picture,
    this.tone = DialogTone.neutral,
    this.iconColor,
    this.discColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null || picture != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _Disc(
                    tone: tone,
                    color: discColor,
                    child:
                        picture ??
                        Icon(
                          icon,
                          size: 64,
                          color: iconColor ?? ToneDisc.colors(palette, tone).$2,
                        ),
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: palette
                      .display(26, weight: FontWeight.w700)
                      .copyWith(height: 34 / 26),
                ),
              ),
              if ((message ?? "").isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: palette.body(16).copyWith(height: 24 / 16),
                  ),
                ),
              if ((note ?? "").isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    note!,
                    textAlign: TextAlign.center,
                    style: palette
                        .body(14)
                        .copyWith(
                          height: 20 / 14,
                          color: palette.secondaryText,
                        ),
                  ),
                ),
              if (footer != null)
                Padding(padding: const EdgeInsets.only(top: 24), child: footer),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 140 pt disc in the tone's soft colour, with a slow pulse ring behind it.
/// The ring pulses three times and then rests, so the screen settles (and
/// tests can wait for it); it stays still when the platform asks for less
/// motion and during integration tests.
class _Disc extends StatefulWidget {
  final DialogTone tone;
  final Color? color;
  final Widget child;

  const _Disc({required this.tone, this.color, required this.child});

  @override
  State<_Disc> createState() => _DiscState();
}

class _DiscState extends State<_Disc> with SingleTickerProviderStateMixin {
  static const double _size = 140;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _pulse.stop();
    } else if (!_started) {
      _started = true;
      _pulse.repeat(count: 3);
    }
  }

  var _started = false;

  static bool _still(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      TestContext.isRunningIntegrationTest(context);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill =
        widget.color ??
        ToneDisc.colors(YiviPalette.of(context), widget.tone).$1;
    final still = _still(context);
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!still)
            Positioned.fill(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    // At rest (before, between and after the pulses) the
                    // ring is fully transparent.
                    final t = Curves.easeOut.transform(_pulse.value);
                    return Transform.scale(
                      scale: 1 + 0.45 * t,
                      child: Opacity(
                        opacity: 0.55 * (1 - t),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: fill,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              child: Center(child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}
