import "package:flutter/material.dart";

import "../theme/theme.dart";
import "irma_close_button.dart";
import "irma_divider.dart";
import "translated_text.dart";

// Inset of the close button from the sheet's top and right edges. The corner
// curve stays concentric with the button: corner radius = button radius (22) + inset.
const double _closeButtonInset = 16.0;
const double _topRadius = 38.0; // 22 (button radius) + 16 (inset)
// Right padding reserved for the title to clear the close button. Held fixed
// (independent of _closeButtonInset) so the title's right-edge stays put.
const double _titleRightReservation = 56.0;

Future<void> showYiviBottomSheet({
  required BuildContext context,
  required String titleKey,
  required Widget child,
  double minHeightFraction = 1 / 3,
  TextStyle? titleStyle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    // backgroundColor inherits from themeData.bottomSheetTheme. elevation and
    // shape are intentionally local: the 38px top radius is computed from the
    // close button inset (see _topRadius), not a brand-wide token.
    elevation: 16,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(_topRadius)),
    ),
    builder: (context) => _YiviBottomSheet(
      titleKey: titleKey,
      minHeightFraction: minHeightFraction,
      titleStyle: titleStyle,
      child: child,
    ),
  );
}

class _YiviBottomSheet extends StatefulWidget {
  final String titleKey;
  final Widget child;
  final double minHeightFraction;
  final TextStyle? titleStyle;

  const _YiviBottomSheet({
    required this.titleKey,
    required this.child,
    required this.minHeightFraction,
    required this.titleStyle,
  });

  @override
  State<_YiviBottomSheet> createState() => _YiviBottomSheetState();
}

class _YiviBottomSheetState extends State<_YiviBottomSheet> {
  final _controller = ScrollController();
  bool _scrolledDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollPositionChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _scrollPositionChanged() {
    final scrolled = _controller.offset > 0;
    if (scrolled != _scrolledDown) {
      setState(() => _scrolledDown = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minHeight =
        MediaQuery.sizeOf(context).height * widget.minHeightFraction;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_topRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              titleKey: widget.titleKey,
              titleStyle: widget.titleStyle,
              scrolled: _scrolledDown,
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String titleKey;
  final TextStyle? titleStyle;
  final bool scrolled;

  const _Header({
    required this.titleKey,
    required this.titleStyle,
    required this.scrolled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        boxShadow: scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.yivi.defaultSpacing,
                    context.yivi.mediumSpacing,
                    _titleRightReservation,
                    context.yivi.mediumSpacing,
                  ),
                  child: TranslatedText(
                    titleKey,
                    style: titleStyle ?? context.text.titleLarge,
                  ),
                ),
                const Positioned(
                  top: _closeButtonInset,
                  right: _closeButtonInset,
                  child: IrmaCloseButton.filled(),
                ),
              ],
            ),
          ),
          const IrmaDivider(),
        ],
      ),
    );
  }
}
