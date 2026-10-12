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

/// Material puts the message of a field this far below its content.
const _messageGap = 4.0;

const _errorIconSize = 14.0;
const _errorIconViewBox = 24.0;

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

  // The message of a TextFormField's validator reaches only its errorBuilder,
  // so the _ReportMessage in there tells this state, to set it as the hint of
  // the field.
  String? _reportedMessage;
  Object? _reporter;

  void _setFocused(bool focused) => setState(() => _focused = focused);

  void _report(Object reporter, String? message) {
    // A message that replaces another is reported before the old one is
    // withdrawn, and the withdrawal must not clear it.
    if (!mounted || (message == null && _reporter != reporter)) {
      return;
    }

    setState(() {
      _reportedMessage = message;
      _reporter = message == null ? null : reporter;
    });
  }

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
        child: InputDecorationTheme(
          data: frame.decorationTheme,
          // Flutter sets an errorText as the hint of the field, but not an
          // error widget.
          child: Semantics(
            hint: formFieldsV2 ? widget.errorText ?? _reportedMessage : null,
            child: frame.field,
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required double labelShift,
    required Widget Function(String) error,
    Widget? helper,
  }) {
    final label = widget.label;
    final errorText = widget.errorText;

    return InputDecoration(
      label: label == null ? null : YiviFieldLabel(label, shift: labelShift),
      hintText: widget.hint,
      suffixIcon: widget.suffixIcon,
      helper: helper,
      error: errorText == null ? null : error(errorText),
    );
  }

  Widget _reporting(String message, Widget child) =>
      _ReportMessage(message: message, report: _report, child: child);

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
        _decoration(labelShift: theme.fieldLabelShift, error: error),
        (_, message) => _reporting(message, error(message)),
        theme.fieldValueStyle,
      ),
    );
  }

  _Frame _rowFrame(BuildContext context, YiviFieldRowPosition position) {
    final theme = IrmaTheme.of(context);
    final last = position == YiviFieldRowPosition.last;
    final bottom = last ? theme.fieldLastRowBottom : theme.fieldRowBottom;

    Widget error(String message) => _RowError(message);

    // Keeps `bottom` of space below the value of a row without a message. The
    // message of an invalid row takes its place, so that the space below the
    // message can differ.
    final spacer = SizedBox(
      height: bottom - theme.fieldRowContentPadding.bottom - _messageGap,
    );

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
      field: widget.builder(
        _decoration(
          labelShift: theme.fieldRowLabelShift,
          error: error,
          helper: spacer,
        ),
        (_, message) => _reporting(message, error(message)),
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

  const _Frame({
    required this.decorationTheme,
    required this.field,
    this.decoration = const BoxDecoration(),
  });
}

/// Passes [message] to [report] once the frame is built, as the field that
/// uses it cannot change while the tree is being built, and withdraws it when
/// this widget goes.
class _ReportMessage extends StatefulWidget {
  final String message;
  final void Function(Object reporter, String? message) report;
  final Widget child;

  const _ReportMessage({
    required this.message,
    required this.report,
    required this.child,
  });

  @override
  State<_ReportMessage> createState() => _ReportMessageState();
}

class _ReportMessageState extends State<_ReportMessage> {
  @override
  void initState() {
    super.initState();
    _report(widget.message);
  }

  @override
  void didUpdateWidget(_ReportMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message) {
      _report(widget.message);
    }
  }

  @override
  void dispose() {
    _report(null);
    super.dispose();
  }

  void _report(String? message) {
    final report = widget.report;
    WidgetsBinding.instance.addPostFrameCallback((_) => report(this, message));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The label of a form fields V2 field. [shift] moves the text down by that
/// many unscaled pixels, to the middle of the line the boards set it on.
class YiviFieldLabel extends StatelessWidget {
  final String text;
  final double shift;

  const YiviFieldLabel(this.text, {super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(offset: Offset(0, shift), child: Text(text));
  }
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
          child: CustomPaint(
            size: const Size.square(_errorIconSize),
            painter: _ErrorIconPainter(disc: theme.error, mark: theme.light),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(message, style: theme.fieldMessageStyle)),
      ],
    );
  }
}

/// A white exclamation mark on a red disc, as drawn on the boards in a 24 px
/// square. Unlike `Icons.error`, the mark is not cut out of the disc, so
/// nothing behind the icon shows through it.
class _ErrorIconPainter extends CustomPainter {
  final Color disc;
  final Color mark;

  const _ErrorIconPainter({required this.disc, required this.mark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _errorIconViewBox);
    canvas.drawCircle(const Offset(12, 12), 11, Paint()..color = disc);

    final markPaint = Paint()
      ..color = mark
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12, 7), const Offset(12, 13), markPaint);
    canvas.drawCircle(const Offset(12, 17), 1.5, markPaint);
  }

  @override
  bool shouldRepaint(_ErrorIconPainter oldDelegate) =>
      oldDelegate.disc != disc || oldDelegate.mark != mark;
}

/// The message of a row, with the red line below it that covers the row's own
/// line. The space below the message, with the line in it, is
/// [IrmaThemeData.fieldRowErrorBottom].
class _RowError extends StatelessWidget {
  final String message;

  const _RowError(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final padding = theme.fieldRowContentPadding;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: theme.fieldRowErrorBottom),
          child: YiviFieldError(message),
        ),
        Positioned(
          left: -padding.left,
          right: -padding.right,
          bottom: 0,
          height: theme.fieldLineWidth,
          child: ColoredBox(color: theme.error),
        ),
      ],
    );
  }
}
