import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";

/// The pill-shaped search field: in the Data and Activity tabs, the add-data
/// and filter sheets and the country picker. You can type in it straight
/// away; a clear button appears once there is text, and clearing puts the
/// cursor back in the field. A tap anywhere on the pill focuses it, not only
/// on the line of text; a tap anywhere outside it puts the keyboard away.
class GlassSearchField extends StatefulWidget {
  /// The field's surface, also of the search field that opens a search
  /// ([HomeTabSearchField]): the surface colour with a thin edge.
  static ShapeDecoration decoration(YiviPalette palette) => ShapeDecoration(
    color: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: YiviCorners.cardRadius,
      side: BorderSide(color: palette.divider),
    ),
  );

  /// The magnifier at the field's start.
  static Icon icon(YiviPalette palette) =>
      Icon(Icons.search, size: 22, color: palette.heading);

  /// The hint's style.
  static TextStyle hintStyle(YiviPalette palette) =>
      palette.body(16).copyWith(color: palette.secondaryText);

  final String hintKey;
  final ValueChanged<String> onChanged;

  /// The search key on the keyboard (Activity: search for the typed words).
  final ValueChanged<String>? onSubmitted;

  /// After the clear button has emptied the field, instead of giving it the
  /// keyboard (Activity: with nothing left asked, the search ends).
  final VoidCallback? onCleared;
  final Key? fieldKey;

  /// Shared with another field for the same search (Add data's field in the
  /// list and in the bar); owned here when null.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double height;

  const GlassSearchField({
    super.key,
    required this.hintKey,
    required this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.height = 48,
  });

  @override
  State<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<GlassSearchField> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  /// Whether there is text: the clear button shows.
  late bool _hasText = _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(GlassSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_changed);
      _controller.addListener(_changed);
      _hasText = _controller.text.isNotEmpty;
    }
  }

  /// The clear button follows the text, also when typed in the other field.
  void _changed() {
    final hasText = _controller.text.isNotEmpty;
    if (mounted && hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  /// The text itself is only a line high in the pill: a tap beside it (on
  /// the magnifier, above or below the text, at the far end) focuses the
  /// field too, with the caret after what is there.
  void _focusField() {
    if (_focus.hasFocus) return;
    final text = _controller.value;
    if (!text.selection.isValid) {
      _controller.selection = TextSelection.collapsed(offset: text.text.length);
    }
    _focus.requestFocus();
  }

  /// Clears the field and gives it the keyboard, also when it had gone
  /// (after the search key): a cleared search is one to type in again.
  void _clear() {
    _controller.clear();
    widget.onChanged("");
    if (widget.onCleared case final cleared?) {
      cleared();
    } else {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final hint = FlutterI18n.translate(context, widget.hintKey);
    // The clear button is part of the field: tapping it keeps the keyboard.
    return TextFieldTapRegion(
      child: DecoratedBox(
        decoration: GlassSearchField.decoration(palette),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusField,
          child: SizedBox(
            height: widget.height,
            child: Row(
              children: [
                const SizedBox(width: 16),
                GlassSearchField.icon(palette),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: widget.fieldKey,
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: palette.body(16),
                    cursorColor: palette.primary,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: GlassSearchField.hintStyle(palette),
                    ),
                  ),
                ),
                if (_hasText)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Semantics(
                      button: true,
                      label: FlutterI18n.translate(
                        context,
                        "wallet.clear_search",
                      ),
                      excludeSemantics: true,
                      child: InkResponse(
                        highlightColor: Colors.transparent,
                        onTap: _clear,
                        radius: 22,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.heading.withValues(alpha: 0.14),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: palette.heading,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
