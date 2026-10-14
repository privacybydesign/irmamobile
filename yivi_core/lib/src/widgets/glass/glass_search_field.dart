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

  const GlassSearchField({
    super.key,
    required this.hintKey,
    required this.onChanged,
    this.fieldKey,
  });

  @override
  State<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<GlassSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged("");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final hint = FlutterI18n.translate(context, widget.hintKey);
    return GlassSurface(
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, size: 22, color: palette.heading),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: widget.fieldKey,
                controller: _controller,
                onChanged: (value) {
                  widget.onChanged(value);
                  setState(() {});
                },
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
                    onTap: _clear,
                    radius: 22,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.heading.withValues(alpha: 0.14),
                      ),
                      child: Icon(Icons.close, size: 16, color: palette.heading),
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
