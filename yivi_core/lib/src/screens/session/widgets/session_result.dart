import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/action_bar.dart";
import "../../../widgets/irma_app_bar.dart";
import "session_columns.dart";
import "session_scaffold.dart";

/// The screen after a session: a picture of what happened ([hero]: the
/// cards received, the hand-over, a disc), what it means ([title], [text],
/// [below]) and the way on ([action]). One look for every result: added,
/// shared, signed, e-mail linked, call now.
///
/// Upright: the hero, the words under it, the button in the bar at the
/// bottom. Held sideways, and on a tablet: the hero at the left, staying
/// put; the words at the right, scrolling, with the button at their foot.
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
    final columns = useSheetColumns(context) || useSessionColumns(context);
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
        body: Builder(
          builder: (context) {
            final media = MediaQuery.paddingOf(context);
            return SidewaysLayout(
              panel: Padding(
                key: const Key("result_panel"),
                padding: EdgeInsets.only(top: 48 + media.top),
                child: Align(alignment: Alignment.topCenter, child: hero),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key("share_done_scroll"),
                      padding: EdgeInsets.only(top: 48 + media.top),
                      child: shown,
                    ),
                  ),
                  if (action case final action?)
                    Padding(
                      padding: EdgeInsets.only(
                        top: YiviSpace.x12,
                        bottom: 21 + media.bottom,
                      ),
                      child: action,
                    ),
                ],
              ),
            );
          },
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
