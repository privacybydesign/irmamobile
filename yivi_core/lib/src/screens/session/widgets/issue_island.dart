import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "requestor_card.dart";

/// Why a card is added during a request, as a dark panel that grows out of
/// the "For {requestor}" pill in the bar ([IssueRequestorPill]), as the
/// Dynamic Island grows: who asks (logo, name, whether Yivi knows them),
/// and that the card is added first and shared with them after.
/// "Got it", or a touch beside it (which still reaches the page), folds it
/// back into the pill.
///
/// The flow puts it over its sheet's pages ([IssueFlow.issueSheet]) when
/// the pill is tapped.
class IssueIsland extends StatefulWidget {
  final TrustedParty requestor;
  final VoidCallback onClose;

  const IssueIsland({
    super.key,
    required this.requestor,
    required this.onClose,
  });

  /// Its distance from the top of the sheet: over the bar, where the pill
  /// is.
  static const double top = 10;

  /// Its distance from the sides: past the bar's buttons (16 + 44 + 4).
  static const double side = 64;

  @override
  State<IssueIsland> createState() => _IssueIslandState();
}

class _IssueIslandState extends State<IssueIsland>
    with SingleTickerProviderStateMixin {
  late final _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _grow.forward();
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Darker than anything on the sheet in light mode; a raised dark grey in
    // dark mode, where black would vanish into the page.
    final fill = dark ? const Color(0xFF2C3036) : const Color(0xFF16191D);
    final style = RequestorTrustStyle.of(context, widget.requestor);
    final sideways = useSheetColumns(context);

    final panel = Semantics(
      key: const Key("issue_island"),
      container: true,
      liveRegion: true,
      child: Container(
        width: sideways ? 520 : double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x47000000),
              blurRadius: 34,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: _content(context, style),
      ),
    );

    return Stack(
      children: [
        // A touch beside the island folds it back, and goes on to what is
        // under it, as with the Dynamic Island: the button you were going
        // to tap still works.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => widget.onClose(),
          ),
        ),
        Positioned(
          top: IssueIsland.top,
          // Clear of the bar's back and close buttons, which stay usable.
          left: IssueIsland.side,
          right: IssueIsland.side,
          child: Align(
            alignment: Alignment.topCenter,
            child: reduceMotion
                ? FadeTransition(opacity: _grow, child: panel)
                : AnimatedBuilder(
                    animation: _grow,
                    builder: (context, child) {
                      // From the pill's size (about 62 % wide, a line high)
                      // to its own, overshooting a little as it settles.
                      final t = YiviMotion.overshoot.transform(_grow.value);
                      final content = Curves.easeOut.transform(
                        ((_grow.value - 0.33) / 0.67).clamp(0.0, 1.0),
                      );
                      return Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.diagonal3Values(
                          0.62 + 0.38 * t,
                          0.12 + 0.88 * t,
                          1,
                        ),
                        child: Opacity(
                          opacity: 0.9 + 0.1 * content,
                          child: child,
                        ),
                      );
                    },
                    child: panel,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, RequestorTrustStyle style) {
    final palette = YiviPalette.of(context);
    final label = style.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 12,
          children: [
            ExcludeSemantics(
              child: requestorAvatar(widget.requestor, size: 40),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.requestor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .display(16)
                        .copyWith(color: Colors.white, height: 21 / 16),
                  ),
                  if (label != null)
                    Text(
                      label,
                      style: palette
                          .body(12.5, weight: FontWeight.w600)
                          .copyWith(color: _onDark(style), height: 17 / 12.5),
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
          child: Text(
            context.tr("issuance.island.body"),
            style: palette
                .body(14.5)
                .copyWith(color: const Color(0xFFE6E9EC), height: 21 / 14.5),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              button: true,
              child: GestureDetector(
                key: const Key("issue_island_ok"),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    context.tr("issuance.island.ok"),
                    style: palette
                        .display(15, weight: FontWeight.w700)
                        .copyWith(color: const Color(0xFF16191D)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The trust label's colour, light enough on the dark panel: the tier's
  /// own hue, lifted.
  Color _onDark(RequestorTrustStyle style) => switch (style.trust) {
    RequestorTrust.yivi => const Color(0xFF7FD6A0),
    RequestorTrust.elsewhere => const Color(0xFF9CC6F0),
    RequestorTrust.unknown => const Color(0xFFF2A0A0),
    RequestorTrust.unevaluated => const Color(0xFFC9CED3),
  };
}
