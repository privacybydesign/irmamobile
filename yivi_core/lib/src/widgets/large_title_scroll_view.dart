import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// A scrolling page that starts with a large title, as on iOS: the question
/// a screen asks ("Do you want to share this data?") in display type, then
/// [children].
///
/// [barTitleVisible] turns true once the large title has scrolled entirely
/// under the floating app bar, and false again when it comes back. Hand the
/// same notifier to `IrmaAppBar(titleVisibility:)`, so the bar shows its
/// short title only while the large one is out of sight.
///
/// Use it as the body of a scaffold with `extendBodyBehindAppBar` and
/// `extendBody`: [padding] should include the bars (see `BarInsets`), so
/// the title starts right below the app bar.
class LargeTitleScrollView extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets padding;
  final ValueNotifier<bool> barTitleVisible;

  /// Space between the title and each of [children].
  final double spacing;

  const LargeTitleScrollView({
    super.key,
    required this.title,
    required this.children,
    required this.padding,
    required this.barTitleVisible,
    this.spacing = 14,
  });

  @override
  State<LargeTitleScrollView> createState() => _LargeTitleScrollViewState();
}

class _LargeTitleScrollViewState extends State<LargeTitleScrollView> {
  final _controller = ScrollController();
  final _titleKey = GlobalKey();
  double? _titleHeight;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The title starts at the top of the content (under the bar, at the top
  /// of [LargeTitleScrollView.padding]), so it has passed under the bar
  /// once the scroll offset reaches its own height.
  void _update() {
    // Kept from the last time it was laid out: scrolled far down, the list
    // no longer builds the title, and coming back to the top the small
    // title would stay in the bar.
    final height = _titleKey.currentContext?.size?.height ?? _titleHeight;
    _titleHeight = height;
    if (height == null || !_controller.hasClients) return;
    final passed = _controller.offset >= height;
    if (widget.barTitleVisible.value != passed) {
      widget.barTitleVisible.value = passed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListView(
      controller: _controller,
      padding: widget.padding,
      children: [
        Padding(
          key: _titleKey,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            header: true,
            child: Text(
              widget.title,
              key: const Key("large_title"),
              style: palette
                  .display(22)
                  .copyWith(height: 30 / 22, color: palette.heading),
            ),
          ),
        ),
        for (final child in widget.children) ...[
          SizedBox(height: widget.spacing),
          child,
        ],
      ],
    );
  }
}
