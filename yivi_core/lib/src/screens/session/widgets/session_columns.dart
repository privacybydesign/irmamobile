import "package:material_ui/material_ui.dart";

import "../../../util/adaptive_layout.dart";

/// Whether the session screens use their two-column tablet layouts.
bool useSessionColumns(BuildContext context) => isExpandedLayout(context);

/// The tablet layout of a session screen: [start] and [end] side by side,
/// top-aligned and centred, with [actions] (the buttons that are in the
/// bottom bar on phones) under [end]. The columns keep their widths while
/// they fit and shrink together when they do not.
class SessionColumns extends StatelessWidget {
  final Widget start;
  final Widget end;
  final Widget? actions;
  final double startWidth;
  final double endWidth;
  final double gap;

  /// Centres the columns vertically, for short content such as a result.
  final bool centreVertically;

  const SessionColumns({
    super.key,
    required this.start,
    required this.end,
    this.actions,
    this.startWidth = 460,
    this.endWidth = 440,
    this.gap = 72,
    this.centreVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: centreVertically
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: startWidth.round(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: startWidth),
            child: start,
          ),
        ),
        SizedBox(width: gap),
        Flexible(
          flex: endWidth.round(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: endWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                end,
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    // The bottom bar keeps its own insets for the phone's
                    // screen edges, which are not needed here.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeLeft: true,
                      removeRight: true,
                      removeBottom: true,
                      child: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: centreVertically
                ? (constraints.maxHeight - 56).clamp(0.0, double.infinity)
                : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: startWidth + gap + endWidth,
              ),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// Frames a full session screen (with its own scaffold) as a centred card
/// for a dialog on tablets, e.g. "Change choice".
class SessionDialogFrame extends StatelessWidget {
  final Widget child;

  const SessionDialogFrame({super.key, required this.child});

  static const double width = 520;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: width,
          height: (size.height * 0.85).clamp(0.0, 760.0),
          child: DecoratedBox(
            decoration: const ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(Radius.circular(38)),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 80,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            child: ClipRSuperellipse(
              borderRadius: const BorderRadius.all(Radius.circular(38)),
              // The screen inside keeps to the card, not the device edges.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                removeLeft: true,
                removeRight: true,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [screen] as a page on phones and as a centred dialog on tablets.
Future<T?> pushSessionSubscreen<T>(BuildContext context, Widget screen) {
  if (useSessionColumns(context)) {
    return showDialog<T>(
      context: context,
      builder: (_) => SessionDialogFrame(child: screen),
    );
  }
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute(builder: (_) => screen));
}
