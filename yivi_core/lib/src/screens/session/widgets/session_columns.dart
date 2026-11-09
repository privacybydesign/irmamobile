import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/fill_scroll_view.dart";
import "../../../widgets/irma_app_bar.dart";

/// The most each column of a session screen's sideways layout is wide (on
/// a phone held sideways about this: the screen less the safe areas, halved).
const double sidewaysColumnMaxWidth = 399;

/// The room between the two columns of a sideways layout.
const double sidewaysColumnGap = 40;

/// The most a session screen's sideways layout is wide, centred.
const double sidewaysMaxWidth = 2 * sidewaysColumnMaxWidth + sidewaysColumnGap;

/// The side margin of a sideways layout: the safe area (59 on an iPhone held
/// sideways), at least 16.
double sidewaysMargin(BuildContext context, {bool end = false}) {
  final insets = MediaQuery.paddingOf(context);
  final inset = end ? insets.right : insets.left;
  return inset < 16 ? 16 : inset;
}

/// Where the left column ([SidewaysLayout.panel]) starts on a screen with
/// its close button in the corner: 28 below the safe area. [context] is
/// under the bar, its top padding the bar's.
double sidewaysPanelTop(BuildContext context) => 28 + _aboveBar(context);

/// Where the right column ([SidewaysLayout.content]) starts: 56 below the
/// safe area, clear of the bar's band it scrolls under.
double sidewaysContentTop(BuildContext context) => 56 + _aboveBar(context);

double _aboveBar(BuildContext context) =>
    (MediaQuery.paddingOf(context).top - IrmaAppBar.toolbarHeight).clamp(
      0.0,
      double.infinity,
    );

/// A session screen's sideways layout (the share screen's, the issuance's,
/// the done screen's), and the same on a tablet: two equal columns, 40
/// apart, inside the safe areas, each at most [sidewaysColumnMaxWidth]; on
/// a wide screen centred. The [panel] at the left stays put (who asks, the
/// button); the [content] at the right scrolls.
class SidewaysLayout extends StatelessWidget {
  final Widget panel;
  final Widget content;

  const SidewaysLayout({super.key, required this.panel, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: sidewaysMargin(context),
        right: sidewaysMargin(context, end: true),
      ),
      child: CentredMaxWidth(
        maxWidth: sidewaysMaxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: sidewaysColumnGap,
          children: [
            Expanded(child: panel),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// Whether the session screens use their two-column tablet layouts: on a
/// tablet held upright. Wider than high they use the layout of a phone held
/// sideways instead ([useSheetColumns]): who asks and the button in a panel
/// at the left, what is shared scrolling at the right.
bool useSessionColumns(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return isExpandedLayout(context) && size.width <= size.height;
}

/// The tablet layout of a session screen: [start] and [end] side by side,
/// top-aligned and centred, with [actions] (the buttons that are in the
/// bottom bar on phones) under [end]. The columns keep their widths while
/// they fit and shrink together when they do not.
///
/// Each column scrolls on its own, as the panel and the content of a phone
/// held sideways: what is shared scrolls at the right, under the bar, while
/// who asks stays where it is (it scrolls only when it is taller than the
/// screen), and the buttons stay in view at the foot of the right column.
/// A short screen ([centreVertically]) is one centred block instead.
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
    if (centreVertically) return _centred(context);

    final insets = BarInsets.of(
      context,
      const EdgeInsets.fromLTRB(32, 24, 32, 32),
    );
    // The bottom bar keeps its own insets for the phone's screen edges,
    // which are not needed here.
    final buttons = actions == null
        ? null
        : MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            removeBottom: true,
            child: actions!,
          );
    return Padding(
      padding: EdgeInsets.only(left: insets.left, right: insets.right),
      child: CentredMaxWidth(
        maxWidth: startWidth + gap + endWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: startWidth.round(),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: startWidth),
                child: SingleChildScrollView(
                  key: const Key("session_columns_start"),
                  padding: EdgeInsets.only(
                    top: insets.top,
                    bottom: insets.bottom,
                  ),
                  child: start,
                ),
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
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key("session_columns_end"),
                        padding: EdgeInsets.only(
                          top: insets.top,
                          bottom: buttons == null ? insets.bottom : 16,
                        ),
                        child: end,
                      ),
                    ),
                    if (buttons != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: insets.bottom),
                        child: buttons,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A short screen: both columns in one block, centred top to bottom.
  Widget _centred(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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

    // The bars are part of the padding: the content is centred between
    // them and only scrolls when it does not fit.
    final padding = BarInsets.of(
      context,
      const EdgeInsets.fromLTRB(32, 24, 32, 32),
    );
    return FillScrollView(
      padding: padding,
      child: CentredMaxWidth(maxWidth: startWidth + gap + endWidth, child: row),
    );
  }
}

/// The bar title of a tablet session screen: hidden, because the question
/// it repeats is always in view at the top of the start column.
const ValueListenable<bool> hiddenBarTitle = AlwaysStoppedAnimation(false);

/// The question a tablet session screen asks ("Do you want to share this
/// data?"), at the top of [SessionColumns.start].
class SessionColumnsTitle extends StatelessWidget {
  final String text;

  const SessionColumnsTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          key: const Key("large_title"),
          style: palette
              .display(30)
              .copyWith(height: 38 / 30, color: palette.heading),
        ),
      ),
    );
  }
}

/// The tablet layout of a short session screen (a result, the call): one
/// column of at most [maxWidth], centred on the screen, with its button
/// under the text instead of across the bottom.
class SessionCentred extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;

  const SessionCentred({
    super.key,
    required this.children,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    // The bars are part of the padding: the content is centred between
    // them and only scrolls when it does not fit.
    final padding = BarInsets.of(
      context,
      const EdgeInsets.fromLTRB(32, 24, 32, 32),
    );
    return FillScrollView(
      padding: padding,
      child: CentredMaxWidth(
        maxWidth: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
