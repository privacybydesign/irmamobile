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
/// that they ask for data you do not have yet, which you are adding now,
/// and that you come back to share it (or sign, [signing]) after.
/// "Got it", or a touch beside it (which still reaches the page), folds it
/// back into the pill.
///
/// The flow puts it over its sheet's pages ([IssueFlow.issueSheet]) when
/// the pill is tapped.
class IssueIsland extends StatefulWidget {
  final TrustedParty requestor;

  /// The request is a signature: you come back to sign.
  final bool signing;
  final VoidCallback onClose;

  const IssueIsland({
    super.key,
    required this.requestor,
    this.signing = false,
    required this.onClose,
  });

  /// Its distance from the top of the sheet: over the bar, where the pill
  /// is.
  static const double top = 10;

  /// Its distance from the sides, upright.
  static const double side = 16;

  /// Held sideways: where it starts from the sheet's left (the pill's
  /// start), and how wide it is.
  static const double sidewaysStart = 103;
  static const double sidewaysWidth = 520;

  @override
  State<IssueIsland> createState() => _IssueIslandState();
}

class _IssueIslandState extends State<IssueIsland>
    with TickerProviderStateMixin {
  /// Grows out of the pill: 420 ms, overshooting a little.
  late final _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Folds back into it: 260 ms.
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _grow.forward();
  }

  @override
  void dispose() {
    _grow.dispose();
    _fold.dispose();
    super.dispose();
  }

  /// Folds back into the pill, then tells the flow it is closed.
  void _close() {
    if (_fold.isAnimating || _fold.value == 1) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onClose();
      return;
    }
    _fold.forward().whenComplete(() {
      if (mounted) widget.onClose();
    });
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

    Widget panel(double radius) => Semantics(
      key: const Key("issue_island"),
      container: true,
      liveRegion: true,
      child: Container(
        width: sideways ? IssueIsland.sidewaysWidth : double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
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

    // Out of the pill and back: from the pill's size (62 % wide, a line
    // high, its round ends) to its own. Its content comes in after it has
    // started to grow, and goes first when it folds.
    final island = reduceMotion
        ? FadeTransition(
            opacity: ReverseAnimation(_fold),
            child: FadeTransition(opacity: _grow, child: panel(30)),
          )
        : AnimatedBuilder(
            animation: Listenable.merge([_grow, _fold]),
            builder: (context, _) {
              final folding = _fold.value > 0;
              final t = folding
                  ? 1 - YiviMotion.leave.transform(_fold.value)
                  : YiviMotion.overshoot.transform(_grow.value);
              final contentIn = folding
                  ? 1 - (_fold.value / (120 / 260)).clamp(0.0, 1.0)
                  : Curves.easeOut.transform(
                      ((_grow.value - 140 / 420) / (260 / 420)).clamp(0.0, 1.0),
                    );
              final opacity = folding ? t : 0.9 + 0.1 * _grow.value;
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform(
                  alignment: sideways ? Alignment.topLeft : Alignment.topCenter,
                  origin: Offset(sideways ? 20 : 0, 22),
                  transform: Matrix4.diagonal3Values(
                    0.62 + 0.38 * t,
                    0.12 + 0.88 * t,
                    1,
                  ),
                  child: _ContentFade(
                    t: contentIn,
                    child: panel(17 + 13 * t.clamp(0.0, 1.0)),
                  ),
                ),
              );
            },
          );

    return Stack(
      children: [
        // A touch beside the island folds it back, and goes on to what is
        // under it, as with the Dynamic Island: the button you were going
        // to tap still works.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _close(),
          ),
        ),
        if (sideways)
          Positioned(
            top: IssueIsland.top,
            left: IssueIsland.sidewaysStart,
            child: island,
          )
        else
          Positioned(
            top: IssueIsland.top,
            left: IssueIsland.side,
            right: IssueIsland.side,
            child: Align(alignment: Alignment.topCenter, child: island),
          ),
      ],
    );
  }

  Widget _content(BuildContext context, RequestorTrustStyle style) => Builder(
    builder: (context) {
      final t = _IslandContentScope.of(context);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -4 * (1 - t)),
          child: _contentColumn(context, style),
        ),
      );
    },
  );

  Widget _contentColumn(BuildContext context, RequestorTrustStyle style) {
    final palette = YiviPalette.of(context);
    final label = style.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 12,
          children: [
            RequestorLogo(requestor: widget.requestor, style: style, size: 40),
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
            context.tr(
              widget.signing
                  ? "issuance.island.body_sign"
                  : "issuance.island.body",
            ),
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
                onTap: _close,
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

/// The island's content at [t]: it fades in from 4 above as the island
/// grows, and out first as it folds (read by [_IssueIslandState._content]).
class _ContentFade extends StatelessWidget {
  final double t;
  final Widget child;

  const _ContentFade({required this.t, required this.child});

  @override
  Widget build(BuildContext context) => _IslandContentScope(t: t, child: child);
}

/// How far the island's content is in, for [_IssueIslandState._content].
class _IslandContentScope extends InheritedWidget {
  final double t;

  const _IslandContentScope({required this.t, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_IslandContentScope>()?.t ?? 1;

  @override
  bool updateShouldNotify(_IslandContentScope old) => old.t != t;
}
