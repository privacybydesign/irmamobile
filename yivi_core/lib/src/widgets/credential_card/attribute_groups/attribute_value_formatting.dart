import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";

// Text styles and value formatting shared by the attribute list and by
// attribute group renderers, so a group can match the look of ordinary rows.
// Renderers are free not to use them.

TextStyle attributeLabelStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: theme.neutralExtraDark,
);

TextStyle attributeValueStyle(IrmaThemeData theme, Color color) => TextStyle(
  fontFamily: theme.primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: color,
);

// Small uppercase Open Sans label.
TextStyle attributeEyebrowStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: theme.neutralDark,
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
