import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// The pill-shaped glass search field at the top of the Data and Activity
/// tabs. You can type in it straight away; a clear button appears once there
/// is text.
class GlassSearchField extends StatefulWidget {
  final String hintKey;
  final ValueChanged<String> onChanged;
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
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged("");
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final hint = FlutterI18n.translate(context, widget.hintKey);
    return GlassSurface(
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
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
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
                  label: FlutterI18n.translate(context, "wallet.clear_search"),
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
    );
  }
}
