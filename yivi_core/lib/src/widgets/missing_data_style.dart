import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

// Colours of the missing data screens that the theme has no token for.
const missingDataSuccessText = Color(0xFF00602A);
const missingDataActionRed = Color(0xFFE12747);
const missingDataDashedBorder = Color(0xFFA3AEB9);
const missingDataMissingFill = Color(0xFFF7FAFC);
const missingDataCloseOnBlue = Color(0xFFB9C9DD);

/// Radius of a row in the list, a bit rounder than `theme.borderRadius`.
final missingDataRowRadius = BorderRadius.circular(10);

/// The heading of the missing data screens: 20 px bold.
TextStyle missingDataHeadingStyle(IrmaThemeData theme) =>
    theme.textTheme.displayMedium!.copyWith(fontSize: 20, height: 28 / 20);

/// The name of a credential in a row or on the card: 16 px, semi bold, black.
TextStyle missingDataNameStyle(IrmaThemeData theme) => theme
    .textTheme
    .bodyMedium!
    .copyWith(fontWeight: FontWeight.w600, height: 22 / 16);

/// Supporting text: 14 px in the dark grey.
TextStyle missingDataCaptionStyle(IrmaThemeData theme) => theme
    .textTheme
    .bodySmall!
    .copyWith(height: 20 / 14, color: theme.neutralExtraDark);

/// A small label: 13 px, semi bold, in the dark grey.
TextStyle missingDataLabelStyle(IrmaThemeData theme) => theme
    .textTheme
    .labelSmall!
    .copyWith(fontSize: 13, height: 18 / 13, color: theme.neutralExtraDark);
