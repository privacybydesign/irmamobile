part of "theme.dart";

// Yivi-specific theme tokens that don't fit Material's standard ThemeData
// shape — domain text styles, brand-only colors, spacing tokens, etc.
//
// Accessed via `context.yivi` (see extension below) or
// `Theme.of(context).extension<YiviThemeExtension>()!`. Both forms work; the
// `context.yivi` getter is the idiomatic choice.
//
// `lerp` and `copyWith` are intentionally minimal — the style groups don't
// interpolate across themes, and partial overrides aren't currently used.
// Both can be filled in if dark-mode animation requires it (Phase 6).
class YiviThemeExtension extends ThemeExtension<YiviThemeExtension> {
  final YiviActivityStyles activity;
  final YiviPinStyles pin;
  final YiviVerificationStyles verification;
  final YiviNfcStyles nfc;
  final YiviFormStyles form;
  final YiviIndicatorStyles indicator;
  final YiviCardStyles card;
  final YiviMiscStyles misc;
  // Brand colours that have no clean Material 3 ColorScheme slot
  // (success/warning/link/danger). Lives here so dark mode in Phase 6 can
  // override it via copyWith/lerp.
  final YiviBrandColors brand;

  // Spacing tokens — Material 3 has no canonical home for these.
  final double tinySpacing;
  final double smallSpacing;
  final double defaultSpacing;
  final double mediumSpacing;
  final double largeSpacing;
  final double hugeSpacing;
  final double screenPadding;
  final BorderRadius borderRadius;

  // Legacy named text styles that pre-date the domain-style groups. Kept
  // because their call sites are non-trivial and they don't fit a TextTheme
  // slot or a domain group.
  final TextStyle textButtonTextStyle;
  final TextStyle mrzLabel;

  final String font;

  YiviThemeExtension({
    required this.activity,
    required this.pin,
    required this.verification,
    required this.nfc,
    required this.form,
    required this.indicator,
    required this.card,
    required this.misc,
    required this.brand,
    required this.tinySpacing,
    required this.smallSpacing,
    required this.defaultSpacing,
    required this.mediumSpacing,
    required this.largeSpacing,
    required this.hugeSpacing,
    required this.screenPadding,
    required this.borderRadius,
    required this.textButtonTextStyle,
    required this.mrzLabel,
    required this.font,
  });

  @override
  YiviThemeExtension copyWith() => this;

  @override
  YiviThemeExtension lerp(ThemeExtension<YiviThemeExtension>? other, double t) {
    if (other is! YiviThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension YiviThemeContext on BuildContext {
  YiviThemeExtension get yivi =>
      Theme.of(this).extension<YiviThemeExtension>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
