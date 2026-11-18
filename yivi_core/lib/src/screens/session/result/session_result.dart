import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../layout/session_layout.dart";
import "../layout/session_scaffold.dart";

/// The screen after a session: a picture of what happened ([hero]: the
/// cards received, the hand-over, a disc), what it means ([title], [text],
/// [below]) and the way on ([action]). One look for every result: added,
/// shared, signed, e-mail linked, call now.
///
/// Upright: the hero, the words under it, the button in the bar at the
/// bottom. Held sideways, and on a tablet: the hero at the top of the
/// panel at the left with the button at its foot ([SessionPanel], as on the
/// share and permission screens); the words at the right, scrolling.
class SessionResult extends StatelessWidget {
  final Widget hero;
  final String title;
  final String text;

  /// Under the text: what to do next, the number to call.
  final Widget? below;

  /// The button; none on iOS where the way back is the system's ◀.
  final Widget? action;

  /// The close button at the top; none when null.
  final VoidCallback? onClose;

  /// A back button at the top left instead; also the system back.
  final VoidCallback? onBack;

  /// The bar's title upright (a translation key); none when null.
  final String? appBarTitle;

  /// The room between the hero and the words, upright.
  final double heroGap;

  /// Wraps the words (the done screen fades them up as the cards land).
  final Widget Function(Widget words)? words;

  final Key titleKey;
  final Key textKey;

  const SessionResult({
    super.key,
    required this.hero,
    required this.title,
    required this.text,
    this.below,
    this.action,
    this.onClose,
    this.onBack,
    this.appBarTitle,
    this.heroGap = 28,
    this.words,
    this.titleKey = const Key("result_title"),
    this.textKey = const Key("result_text"),
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final columns = SessionLayout.of(context).split;
    final below = this.below;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            key: titleKey,
            textAlign: columns ? TextAlign.start : TextAlign.center,
            style: palette.titleResult.copyWith(
              height: 34 / 26,
              color: palette.text,
            ),
          ),
        ),
        SizedBox(height: columns ? 12 : 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: columns ? 0 : 24),
          child: Text(
            text,
            key: textKey,
            textAlign: columns ? TextAlign.start : TextAlign.center,
            style: palette
                .body(16)
                .copyWith(height: 24 / 16, color: palette.text),
          ),
        ),
        if (below != null) ...[const SizedBox(height: YiviSpace.x16), below],
      ],
    );
    final shown = words?.call(content) ?? content;
    final back = onBack;
    final leading = back == null ? null : YiviBackButton(onTap: back);

    final Widget screen;
    if (columns) {
      screen = SessionScaffold(
        onDismiss: onClose,
        leading: leading,
        wide: true,
        scrollsUnderBars: true,
        cornerClose: true,
        // The body's own context sees the bars.
        body: Builder(
          builder: (context) => SidewaysLayout(
            panel: SessionPanel(
              key: const Key("result_panel"),
              top: Center(child: hero),
              action: action,
              fitTop: true,
            ),
            content: SessionPanelContent(
              scrollKey: const Key("share_done_scroll"),
              children: [shown],
            ),
          ),
        ),
      );
    } else {
      screen = SessionScaffold(
        onDismiss: onClose,
        leading: leading,
        appBarTitle: appBarTitle,
        scrollsUnderBars: true,
        body: BarInsetsBuilder(
          builder: (context, insets) => ListView(
            padding:
                insets +
                const EdgeInsets.fromLTRB(
                  YiviSpace.x16,
                  0,
                  YiviSpace.x16,
                  YiviSpace.x24,
                ),
            children: [
              Center(child: hero),
              SizedBox(height: heroGap),
              shown,
            ],
          ),
        ),
        bottomNavigationBar: switch (action) {
          final action? => ActionBar(actions: [action]),
          null => null,
        },
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back?.call();
      },
      child: screen,
    );
  }
}
