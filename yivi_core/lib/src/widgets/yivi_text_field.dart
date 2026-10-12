import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../data/feature_flags.dart";
import "../providers/feature_flag_provider.dart";
import "../theme/theme.dart";
import "yivi_field_group.dart";

/// Builds the field with the [decoration] to use. A `TextFormField` takes
/// [errorBuilder] too, and [style] for its value; both are null when the field
/// keeps its old look.
typedef YiviTextFieldBuilder =
    Widget Function(
      InputDecoration decoration,
      FormFieldErrorBuilder? errorBuilder,
      TextStyle? style,
    );

const _dividerWidth = 1.0;

/// A text field that is white with its label inside when
/// [FeatureFlag.formFieldsV2] is on, and keeps its old look when it is off.
///
/// [builder] creates the `TextField` or `TextFormField`, so that a screen
/// keeps control of everything but the decoration. Below a [YiviFieldGroup]
/// the field renders as a row of the group.
class YiviTextField extends ConsumerStatefulWidget {
  /// The decoration used, as is, with the flag off.
  final InputDecoration legacyDecoration;

  /// Shown inside the field with the flag on.
  final String? label;
  final String? hint;
  final Widget? suffixIcon;

  /// For a `TextField`; a `TextFormField` shows its validator's message.
  final String? errorText;
  final YiviTextFieldBuilder builder;

  const YiviTextField({
    super.key,
    required this.legacyDecoration,
    required this.builder,
    this.label,
    this.hint,
    this.suffixIcon,
    this.errorText,
  });

  @override
  ConsumerState<YiviTextField> createState() => _YiviTextFieldState();
}

class _YiviTextFieldState extends ConsumerState<YiviTextField> {
  var _focused = false;

  void _setFocused(bool focused) => setState(() => _focused = focused);

  @override
  Widget build(BuildContext context) {
    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;
    final position = formFieldsV2 ? YiviFieldGroup.rowPosition(context) : null;

    final frame = !formFieldsV2
        ? _legacyFrame(context)
        : position == null
        ? _singleFrame(context)
        : _rowFrame(context, position);

    // The same widgets with the flag off and on, so that the field is not
    // rebuilt from scratch, dropping its text input connection, when the flag
    // value arrives a frame after the screen opens.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: position == null ? null : _setFocused,
      child: DecoratedBox(
        decoration: frame.decoration,
        child: Padding(
          padding: EdgeInsets.only(bottom: frame.bottom),
          child: InputDecorationTheme(
            data: frame.decorationTheme,
            child: frame.field,
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(Widget Function(String) error) {
    final errorText = widget.errorText;

    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      suffixIcon: widget.suffixIcon,
      error: errorText == null ? null : error(errorText),
    );
  }

  _Frame _legacyFrame(BuildContext context) {
    return _Frame(
      decorationTheme: InputDecorationTheme.of(context),
      field: widget.builder(widget.legacyDecoration, null, null),
    );
  }

  _Frame _singleFrame(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // The message lines up with the edge of the field, not with its text.
    Widget error(String message) => Transform.translate(
      offset: Offset(-theme.fieldInset, 0),
      child: YiviFieldError(message),
    );

    return _Frame(
      decorationTheme: theme.fieldDecorationTheme,
      field: widget.builder(
        _decoration(error),
        (_, message) => error(message),
        theme.fieldValueStyle,
      ),
    );
  }

  _Frame _rowFrame(BuildContext context, YiviFieldRowPosition position) {
    final theme = IrmaTheme.of(context);
    final last = position == YiviFieldRowPosition.last;
    final bottom = last ? theme.fieldLastRowBottom : theme.fieldRowBottom;

    Widget error(String message) => _RowError(message, bottom: bottom);

    // A row that is last has no divider, as the card ends there. The line of a
    // row with an error is drawn by [_RowError].
    final BorderSide line = _focused
        ? BorderSide(color: theme.link, width: theme.fieldLineWidth)
        : last
        ? BorderSide.none
        : BorderSide(color: theme.neutralExtraLight, width: _dividerWidth);

    return _Frame(
      decorationTheme: theme.fieldRowDecorationTheme,
      decoration: BoxDecoration(border: Border(bottom: line)),
      bottom: bottom,
      field: widget.builder(
        _decoration(error),
        (_, message) => error(message),
        theme.fieldRowValueStyle,
      ),
    );
  }
}

class _Frame {
  final InputDecorationThemeData decorationTheme;
  final Widget field;

  /// Behind the field, with the line of a row.
  final BoxDecoration decoration;

  /// The space the line of a row is in, below the field.
  final double bottom;

  const _Frame({
    required this.decorationTheme,
    required this.field,
    this.decoration = const BoxDecoration(),
    this.bottom = 0,
  });
}

/// An error message with an icon, shown below a field.
class YiviFieldError extends StatelessWidget {
  final String message;

  const YiviFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(Icons.error, size: 14, color: theme.error),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(message, style: theme.fieldMessageStyle)),
      ],
    );
  }
}

/// The message of a row. It is shown in the space of the row, with the red
/// line below it drawn over the row's own line, [bottom] below the message.
class _RowError extends StatelessWidget {
  final String message;
  final double bottom;

  const _RowError(this.message, {required this.bottom});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final padding = theme.fieldRowContentPadding;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        YiviFieldError(message),
        Positioned(
          left: -padding.left,
          right: -padding.right,
          bottom: -bottom,
          height: theme.fieldLineWidth,
          child: ColoredBox(color: theme.error),
        ),
      ],
    );
  }
}
