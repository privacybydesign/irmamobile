import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// The pill-shaped glass search field at the top of the Data and Activity
/// tabs. You can type in it straight away; a clear button appears once there
/// is text. A tap anywhere on the pill focuses it, not only on the line of
/// text; a tap anywhere outside it puts the keyboard away.
class GlassSearchField extends StatefulWidget {
  final String hintKey;
  final ValueChanged<String> onChanged;

  /// The search key on the keyboard (Activity: search for the typed words).
  final ValueChanged<String>? onSubmitted;
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
    }
  }

  /// The clear button follows the text, also when typed in the other field.
  void _changed() {
    if (mounted) setState(() {});
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

  void _clear() {
    _controller.clear();
    widget.onChanged("");
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final hint = FlutterI18n.translate(context, widget.hintKey);
    // The clear button is part of the field: tapping it keeps the keyboard.
    return TextFieldTapRegion(
      child: GlassSurface(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusField,
          child: SizedBox(
            height: widget.height,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, size: 22, color: palette.heading),
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
                      hintStyle: palette
                          .body(16)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
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
