import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "pill_text_field.dart";

/// A one-time code entered as a row of digit boxes, over a hidden text field
/// that takes the keyboard, paste and the platform's one-time-code autofill.
class CodeInput extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Called once all [length] digits are in.
  final ValueChanged<String>? onCompleted;

  final String? label;

  /// Marks every box red and shows the message below them.
  final String? errorText;

  final bool autofocus;
  final Key? fieldKey;

  const CodeInput({
    super.key,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.onCompleted,
    this.label,
    this.errorText,
    this.autofocus = true,
    this.fieldKey,
  });

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final code = _controller.text;
    final hasError = (widget.errorText ?? "").isNotEmpty;

    final boxes = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < widget.length; i++)
          Flexible(
            child: CodeBox(
              char: i < code.length ? code[i] : "",
              borderColor: hasError
                  ? palette.danger
                  : _focus.hasFocus && i == code.length
                  ? palette.link
                  : palette.outline,
            ),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: palette
                  .body(14, weight: FontWeight.w600)
                  .copyWith(height: 20 / 14, color: palette.heading),
            ),
          ),
        Stack(
          children: [
            ExcludeSemantics(child: boxes),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    labelText: widget.label,
                  ),
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    if (value.length == widget.length) {
                      widget.onCompleted?.call(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        if (hasError) FieldError(widget.errorText!, align: TextAlign.center),
      ],
    );
  }
}

/// One box of a code: also used read-only for a pairing code.
class CodeBox extends StatelessWidget {
  final String char;
  final Color? borderColor;
  final double width;
  final double height;

  const CodeBox({
    super.key,
    required this.char,
    this.borderColor,
    this.width = 48,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? palette.outline, width: 2),
        ),
        child: Text(
          char,
          style: palette.display(height * 0.43, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
