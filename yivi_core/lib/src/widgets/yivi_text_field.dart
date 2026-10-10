import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../data/feature_flags.dart";
import "../providers/feature_flag_provider.dart";
import "../theme/theme.dart";
import "yivi_field_group.dart";

/// Builds the field with the [decoration] to use. A `TextFormField` takes
/// [errorBuilder] too; it is null when the field keeps its old look.
typedef YiviTextFieldBuilder =
    Widget Function(
      InputDecoration decoration,
      FormFieldErrorBuilder? errorBuilder,
    );

/// A text field that is white with its label inside when
/// [FeatureFlag.formFieldsV2] is on, and keeps its old look when it is off.
///
/// [builder] creates the `TextField` or `TextFormField`, so that a screen
/// keeps control of everything but the decoration. Below a [YiviFieldGroup]
/// the field renders as a row of the group.
class YiviTextField extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

    // The theme widget is there with the flag off too, so that the field is not
    // rebuilt from scratch, losing its focus, when the flag value arrives.
    if (!formFieldsV2) {
      return InputDecorationTheme(
        data: InputDecorationTheme.of(context),
        child: builder(legacyDecoration, null),
      );
    }

    final theme = IrmaTheme.of(context);
    final errorText = this.errorText;

    return InputDecorationTheme(
      data: YiviFieldGroup.contains(context)
          ? theme.fieldRowDecorationTheme
          : theme.fieldDecorationTheme,
      child: builder(
        InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          error: errorText == null ? null : YiviFieldError(errorText),
        ),
        (_, message) => YiviFieldError(message),
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.error_outline, size: 20, color: theme.error),
        ),
        SizedBox(width: theme.tinySpacing),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.error),
          ),
        ),
      ],
    );
  }
}
