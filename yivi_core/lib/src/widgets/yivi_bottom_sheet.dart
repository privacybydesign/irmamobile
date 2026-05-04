import "package:flutter/material.dart";

import "../theme/theme.dart";
import "credential_card/yivi_credential_card_header.dart";
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(_topRadius)),
    ),
    builder: (context) => _YiviBottomSheet(titleKey: titleKey, child: child),
  );
}

class _YiviBottomSheet extends StatefulWidget {
  final String titleKey;
  final Widget child;

  const _YiviBottomSheet({required this.titleKey, required this.child});

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
    final theme = IrmaTheme.of(context);
    final minHeight = MediaQuery.sizeOf(context).height / 3;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_topRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(titleKey: widget.titleKey, scrolled: _scrolledDown),
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
  final bool scrolled;

  const _Header({required this.titleKey, required this.scrolled});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
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
                    theme.defaultSpacing,
                    theme.mediumSpacing,
                    _titleRightReservation,
                    theme.mediumSpacing,
                  ),
                  child: TranslatedText(
                    titleKey,
                    style: credentialNameStyle(
                      theme,
                      19,
                    ).copyWith(fontWeight: FontWeight.w600),
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
