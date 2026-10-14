import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";

// Text styles and value formatting shared by the attribute list and by
// attribute group renderers, so a group can match the look of ordinary rows.
// Renderers are free not to use them.

/// Text colours for attribute rows, which follow the app's brightness so the
/// list stays readable in dark mode.
class AttributeColors {
  final Color value;
  final Color label;
  final Color eyebrow;
  final Color muted;
  final Color divider;

  const AttributeColors._({
    required this.value,
    required this.label,
    required this.eyebrow,
    required this.muted,
    required this.divider,
  });

  static AttributeColors of(BuildContext context) {
    final theme = IrmaTheme.of(context);
    if (Theme.of(context).brightness == Brightness.dark) {
      return const AttributeColors._(
        value: Color(0xFFF2F2F4),
        label: Color(0xFFB4B4BC),
        eyebrow: Color(0xFF9A9AA3),
        muted: Color(0xFF85858E),
        divider: Color(0x24FFFFFF),
      );
    }
    return AttributeColors._(
      value: theme.dark,
      label: theme.neutralExtraDark,
      eyebrow: theme.neutralDark,
      muted: theme.neutral,
      divider: theme.neutralExtraLight,
    );
  }
}

TextStyle attributeLabelStyle(BuildContext context) => TextStyle(
  fontFamily: IrmaTheme.of(context).secondaryFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AttributeColors.of(context).label,
);

TextStyle attributeValueStyle(BuildContext context, Color color) => TextStyle(
  fontFamily: IrmaTheme.of(context).primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: color,
);

// Small uppercase Open Sans label.
TextStyle attributeEyebrowStyle(BuildContext context) => TextStyle(
  fontFamily: IrmaTheme.of(context).secondaryFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AttributeColors.of(context).eyebrow,
  letterSpacing: 0.96, // 0.08em × 12px
);

String formatAttributeBool(BuildContext context, bool? value) {
  if (value == null) return "";
  return FlutterI18n.translate(
    context,
    value ? "credential.boolean_yes" : "credential.boolean_no",
  );
}

/// Decodes an image attribute value, or returns null when it holds no usable
/// image. Issuers sometimes fill an empty image attribute with a placeholder
/// such as " "; decoding that throws during build and greys out the whole card.
Uint8List? decodeAttributeImage(schemaless.AttributeValue? value) {
  final raw = value?.imagePath ?? value?.base64Image ?? "";
  final Uint8List bytes;
  try {
    bytes = const Base64Decoder().convert(raw.trim());
  } on FormatException {
    return null;
  }
  return bytes.isEmpty ? null : bytes;
}
