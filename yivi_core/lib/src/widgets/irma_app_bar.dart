import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "glass/glass_surface.dart";
import "glass/pill_buttons.dart";
import "glass/scroll_edge.dart";
import "translated_text.dart";

class YiviAppBarQrCodeButton extends StatelessWidget {
  const YiviAppBarQrCodeButton({super.key, this.onTap});

  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // The bar puts it 16 from the edges, like the other buttons.
    return PlainIconButton(
      icon: Icons.qr_code_scanner_rounded,
      iconSize: 28,
      semanticsLabel: FlutterI18n.translate(context, "home.nav_bar.scan_qr"),
      onPressed: onTap ?? () {},
    );
  }
}

/// The round glass back button at the start of an app bar.
class YiviBackButton extends StatelessWidget {
  final Function()? onTap;

  const YiviBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      key: const Key("irma_app_bar_leading"),
      semanticsLabel: FlutterI18n.translate(context, "ui.go_back"),
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 22,
        color: YiviPalette.of(context).text,
      ),
      onTap: () {
        if (onTap == null) {
          Navigator.of(context).pop();
        } else {
          onTap!();
        }
      },
    );
  }
}

/// The bar at the top of a screen, as in the design: no bar of its own, but
/// the title and round glass buttons floating over the page, 16 from the
/// edges, with the page colour fading out below them so the content can
/// scroll underneath (see [BarInsets] and `extendBodyBehindAppBar`).
///
/// Unlike Material's AppBar it does not clip, so the glass buttons keep their
/// soft shadow.
class IrmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 16 above the 44 pt buttons and the buttons themselves.
  static const double toolbarHeight = 60;

  final String? titleTranslationKey;
  final String? titleString;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;

  /// A solid bar with a line under it, for the screens of the old design.
  final bool hasBorder;
  final PreferredSizeWidget? bottom;

  /// Shows the title only while true, fading it in and out. For screens
  /// whose content starts with a large title (see `LargeTitleScrollView`),
  /// as on iOS: the bar's title appears once the large one has scrolled
  /// under the bar. Null keeps the title always visible.
  final ValueListenable<bool>? titleVisibility;

  IrmaAppBar({
    this.titleTranslationKey,
    this.titleString,
    this.title,
    this.leading = const YiviBackButton(),
    this.actions = const [],
    this.hasBorder = false,
    this.bottom,
    this.titleVisibility,
  }) : assert(
         [title, titleTranslationKey, titleString].nonNulls.length == 1,
         "only one of them can be non-null",
       );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    final Widget plainTitle = Semantics(
      header: true,
      namesRoute: true,
      child: DefaultTextStyle.merge(
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child:
            title ??
            TranslatedText(
              titleTranslationKey ?? (titleString ?? ""),
              style: palette.display(18).copyWith(color: palette.text),
              textAlign: TextAlign.center,
            ),
      ),
    );
    final visibility = titleVisibility;
    final titleWidget = visibility == null
        ? plainTitle
        : ValueListenableBuilder<bool>(
            valueListenable: visibility,
            builder: (context, visible, child) => ExcludeSemantics(
              // The large title on the page says the same while this one
              // is hidden.
              excluding: !visible,
              child: AnimatedOpacity(
                key: const Key("irma_app_bar_title"),
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: child,
              ),
            ),
            child: plainTitle,
          );

    final toolbar = SizedBox(
      height: toolbarHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 + padding.left,
          16,
          16 + padding.right,
          0,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // The title keeps clear of a 44 pt button on either side.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Center(child: titleWidget),
            ),
            if (leading != null)
              Align(alignment: Alignment.centerLeft, child: leading),
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );

    final content = Padding(
      padding: EdgeInsets.only(top: padding.top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [toolbar, ?bottom],
      ),
    );

    if (hasBorder) {
      return DecoratedBox(
        key: const Key("irma_app_bar"),
        decoration: BoxDecoration(
          color: palette.background,
          border: Border(bottom: BorderSide(color: theme.tertiary)),
        ),
        child: content,
      );
    }

    // Behind the status bar and the buttons: the hard scroll edge once the
    // page's content is under the bar (see [ScrollEdgeBand]).
    return Stack(
      key: const Key("irma_app_bar"),
      children: [
        const Positioned.fill(child: _AppBarEdge()),
        content,
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// What a screen under a floating [IrmaAppBar] and bottom bar needs: with
/// `extendBodyBehindAppBar` and `extendBody` the scaffold reports both bars
/// in the body's media padding, and the scrolling content adds them to its
/// own padding, so it starts below the bars but scrolls underneath them.
class BarInsets {
  BarInsets._();

  /// [base] plus the bars (and the safe areas) above and below the content.
  static EdgeInsets of(
    BuildContext context, [
    EdgeInsets base = EdgeInsets.zero,
  ]) {
    final padding = MediaQuery.paddingOf(context);
    return base +
        EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          padding.bottom,
        );
  }
}

/// Builds [builder] with [BarInsets.of] its own context: use it directly in a
/// scaffold's body, where the screen's own context does not see the bars yet.
class BarInsetsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, EdgeInsets insets) builder;

  const BarInsetsBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, BarInsets.of(context));
}

/// The scroll edge of an [IrmaAppBar]: it follows the page's scroll view
/// through the [Scaffold]'s [ScrollNotificationObserver], as a Material app
/// bar knows it is scrolled under. Outside a scaffold it never shows.
class _AppBarEdge extends StatefulWidget {
  const _AppBarEdge();

  @override
  State<_AppBarEdge> createState() => _AppBarEdgeState();
}

class _AppBarEdgeState extends State<_AppBarEdge> {
  final _under = ScrollEdgeNotifier();
  ScrollNotificationObserverState? _observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer == _observer) return;
    _observer?.removeListener(_onScroll);
    _observer = observer?..addListener(_onScroll);
  }

  void _onScroll(ScrollNotification notification) =>
      _under.handle(notification);

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollEdgeBand(under: _under);
}
