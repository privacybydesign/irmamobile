part of "theme.dart";

// Spacing scale + the outer screen gutter.
//
// The 6-step ladder (`tiny` → `huge`) is the spacing system used for
// padding, gaps, and SizedBox heights. `screenPadding` is a semantic
// alias for the scaffold-body gutter — same value as `base` today, but
// kept as a named field so screens can express intent ("this is the
// screen edge padding, not a generic gap").
//
// The "default" spacing unit (16dp) is exposed as `base` rather than
// `default` because `default` is a reserved word in Dart.
//
// `borderRadius` is NOT a spacing-scale member — it lives directly on
// YiviThemeExtension.
class YiviSpacing {
  final double tiny;
  final double small;
  final double base;
  final double medium;
  final double large;
  final double huge;
  final double screenPadding;

  const YiviSpacing({
    required this.tiny,
    required this.small,
    required this.base,
    required this.medium,
    required this.large,
    required this.huge,
    required this.screenPadding,
  });
}
