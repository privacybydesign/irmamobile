part of "theme.dart";

// Yivi brand colours that don't fit Material 3's ColorScheme slots. MD3 has
// `primary`, `secondary`, `tertiary`, `error` containers but no semantic slots
// for success / warning / link / deprecated-state surfaces. We keep these on
// the ThemeExtension so dark-mode (Phase 6) can swap them as a unit.
class YiviBrandColors {
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color link;
  final Color danger;
  // Mid-grey used for muted decorative bits (bullet dots, etc.). Sits between
  // outlineVariant (#D7D2CD) and outline (#757375) on the neutral scale; no
  // direct MD3 slot maps cleanly.
  final Color neutral;
  // Very light beige used for dividers, separator lines, and the avatar
  // fallback background. Lighter than outlineVariant but not pure white.
  final Color neutralExtraLight;

  const YiviBrandColors({
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.link,
    required this.danger,
    required this.neutral,
    required this.neutralExtraLight,
  });
}
