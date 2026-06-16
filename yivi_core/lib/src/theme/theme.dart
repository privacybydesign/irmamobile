import "package:flutter/material.dart";
import "package:flutter/services.dart";

part "brand_colors.dart";
part "text_styles.dart";
part "yivi_theme_extension.dart";

/// Build the Yivi-themed [ThemeData] — wires up colors, text theme, component
/// themes, and the [YiviThemeExtension] that carries domain styles and brand
/// tokens. Call once per [MaterialApp] (e.g. `theme: buildYiviThemeData()`).
ThemeData buildYiviThemeData() {
  // ──────────────────────────────────────────────────────────────────────
  // Palette — brand colors, neutrals, and the few state/affordance colors
  // that don't fit a Material 3 ColorScheme slot. The "no MD3 slot" ones
  // flow into YiviBrandColors at the bottom of this function.
  // ──────────────────────────────────────────────────────────────────────
  const primary = Color(0xFFBA3354);
  const tertiary = Color(0xFFCFE4EF);
  const dark = Colors.black;
  const light = Colors.white;
  const neutralExtraDark = Color(0xFF484747);
  const neutralDark = Color(0xFF757375);
  const neutral = Color(0xFF9F9A9A);
  const neutralLight = Color(0xFFD7D2CD);
  const neutralExtraLight = Color(0xFFEAE5E2);
  const backgroundSecondary = Color(0xFFFAFAFA);
  // backgroundTertiary == surfaceSecondary in the legacy palette — both
  // #EAF3F9. MD3 collapses them onto a single elevation tier.
  const backgroundTertiary = Color(0xFFEAF3F9);
  const surfaceTertiary = Color(0xffF0DEDE);
  const error = Color(0xFFBD1919);
  const errorSurface = Color(0xFFF5DBDB);
  const warning = Color(0xFFEBA73B);
  const success = Color(0xFF00973A);
  const successSurface = Color(0xFFD7EFE0);
  const link = Color(0xFF1D4E89);
  const danger = Color(0xffEABEBE);
  // `secondary` is an alias for neutralExtraDark in the current palette —
  // used for buttons and headlines that should read as "dark UI surface
  // foreground" rather than as the brand red.
  const secondary = neutralExtraDark;

  const font = "Open Sans";

  // ──────────────────────────────────────────────────────────────────────
  // Spacing tokens, border radius.
  // ──────────────────────────────────────────────────────────────────────
  const spaceBase = 16.0;
  const tinySpacing = spaceBase / 4; // 4
  const smallSpacing = spaceBase / 2; // 8
  const defaultSpacing = spaceBase; // 16
  const mediumSpacing = spaceBase * 1.5; // 24
  const largeSpacing = spaceBase * 2; // 32
  const hugeSpacing = spaceBase * 4; // 64
  const screenPadding = defaultSpacing;
  final borderRadius = BorderRadius.circular(8);

  // ──────────────────────────────────────────────────────────────────────
  // ColorScheme — MD3 slots mapped from the Yivi palette above. Slots with
  // no clean Yivi mapping (primaryContainer, secondaryContainer,
  // tertiaryContainer) are left to Flutter's defaults until Phase 6 picks
  // them up alongside the dark scheme. See plan-theming-architecture.md
  // §4 Phase 3 for the mapping rationale.
  // ──────────────────────────────────────────────────────────────────────
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: light,
    secondary: secondary,
    onSecondary: light,
    tertiary: tertiary,
    onTertiary: dark,
    error: error,
    onError: light,
    errorContainer: errorSurface,
    onErrorContainer: dark,
    surface: light,
    onSurface: dark,
    onSurfaceVariant: neutralExtraDark,
    surfaceContainerLow: backgroundSecondary,
    surfaceContainerHigh: backgroundTertiary,
    surfaceContainerHighest: surfaceTertiary,
    outline: neutralDark,
    outlineVariant: neutralLight,
  );

  // ──────────────────────────────────────────────────────────────────────
  // TextTheme.
  // ──────────────────────────────────────────────────────────────────────
  final textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: font,
      fontSize: 26,
      height: 36 / 26,
      fontWeight: FontWeight.w700,
      color: neutralExtraDark,
    ),
    displayMedium: TextStyle(
      fontFamily: font,
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      color: neutralExtraDark,
    ),
    displaySmall: TextStyle(
      fontFamily: font,
      fontSize: 18,
      height: 36 / 18,
      fontWeight: FontWeight.w600,
      color: neutralExtraDark,
    ),
    headlineMedium: TextStyle(
      fontFamily: font,
      fontSize: 16.0,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      color: neutralExtraDark,
    ),
    headlineSmall: TextStyle(
      fontFamily: font,
      fontSize: 16.0,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: neutralExtraDark,
    ),
    titleLarge: TextStyle(
      fontSize: 10,
      height: 16 / 10,
      fontWeight: FontWeight.w500,
      color: neutralExtraDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: font,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      color: dark,
    ),
    bodyMedium: TextStyle(
      fontFamily: font,
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.w400,
      color: dark,
    ),
    labelSmall: TextStyle(
      fontSize: 12.0,
      height: 16.0 / 12.0,
      fontWeight: FontWeight.w600,
      color: dark,
    ),
    titleMedium: TextStyle(
      fontSize: 16.0,
      height: 22.0 / 18.0,
      fontWeight: FontWeight.normal,
      color: dark,
    ),
    bodySmall: TextStyle(
      fontFamily: font,
      fontSize: 14.0,
      height: 1.4,
      fontWeight: FontWeight.w400,
      color: neutralExtraDark,
    ),
    labelLarge: TextStyle(
      fontFamily: font,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w700,
      color: light,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────
  // Legacy named text styles. Pre-date the domain-style groups and don't
  // fit a TextTheme slot or a domain group.
  // ──────────────────────────────────────────────────────────────────────
  const textButtonTextStyle = TextStyle(
    fontSize: 16.0,
    height: 19.0 / 16.0,
    fontWeight: FontWeight.w600,
    color: secondary,
  );
  const hyperlinkTextStyle = TextStyle(
    fontFamily: font,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w700,
    color: link,
    decoration: TextDecoration.underline,
  );
  const mrzLabel = TextStyle(
    fontFamily: "monospace",
    fontSize: 14,
    color: light,
    letterSpacing: 2,
  );

  // ──────────────────────────────────────────────────────────────────────
  // Domain text-style groups. Each group bundles the text styles for one
  // usage area (credential card, PIN entry, NFC reading, etc.). Variable
  // colour or shape variants are encoded as builder methods on the group.
  // ──────────────────────────────────────────────────────────────────────
  final credential = YiviCredentialStyles(
    // TODO Phase 2: snap to 18 or extend scale to include 19.
    name: const TextStyle(
      fontFamily: font,
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: dark,
      height: 26 / 19,
    ),
    attributeEyebrow: const TextStyle(
      fontFamily: font,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: neutralDark,
      letterSpacing: 0.96,
    ),
    // Tighter line height for stacked list items (bullets) so successive
    // values don't drift apart vertically.
    attributeBulletValue: const TextStyle(
      fontFamily: font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: dark,
      height: 1.2,
    ),
    attributeValue: (color) => TextStyle(
      fontFamily: font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    expiryNote: (color) => textTheme.bodyLarge!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    // "Revoked" / "Expired" / "About to expire" status text above a
    // credential card header. Color is state-driven (error / warning).
    statusText: (color) =>
        textTheme.headlineMedium!.copyWith(color: color),
  );

  final activity = YiviActivityStyles(
    cardTitle: textTheme.headlineMedium!.copyWith(
      fontSize: 16,
      color: dark,
    ),
    detailDate: textTheme.displaySmall!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: dark,
    ),
  );

  final pin = YiviPinStyles(
    keypadDigit: const TextStyle(
      fontFamily: font,
      fontSize: 32,
      height: 32 / 40,
      fontWeight: FontWeight.w600,
      color: secondary,
    ),
    keypadSubtitle: const TextStyle(
      fontFamily: font,
      height: 14 / 24,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
    warningHeading: textTheme.headlineSmall!.copyWith(
      fontWeight: FontWeight.w700,
    ),
    warningButton: textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: warning,
    ),
    counter: (visible) => textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w300,
      color: visible ? secondary : Colors.transparent,
    ),
    // `boxHeight` is the box's outer height in logical pixels — the digit's
    // fontSize scales from it so the glyph sits proportionally inside.
    box: (boxHeight, completed) => textTheme.displaySmall!.copyWith(
      fontSize: boxHeight / 2 + 4,
      height: 22.0 / 18.0,
      color: completed ? secondary : Colors.grey,
    ),
  );

  final verification = YiviVerificationStyles(
    codeChar: const TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w600,
      color: Color.fromRGBO(30, 60, 87, 1),
    ),
  );

  final nfc = YiviNfcStyles(
    statusTitle: textTheme.bodyLarge!.copyWith(fontSize: 20),
    progressTip: const TextStyle(
      fontSize: 16,
      color: secondary,
      height: 1.4,
      overflow: TextOverflow.visible,
    ),
  );

  final form = YiviFormStyles(
    errorMessage: const TextStyle(color: error),
    inputHint: const TextStyle(color: Colors.grey),
    explanation: textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      color: neutralDark,
    ),
    // Color matches colorScheme.onSurfaceVariant.
    header: textTheme.bodyLarge!.copyWith(color: neutralExtraDark),
  );

  final indicator = YiviIndicatorStyles(
    endOfList: textTheme.bodyMedium!.copyWith(
      fontSize: 12,
      height: 18 / 12,
      color: neutralExtraDark,
    ),
    linearStep: const TextStyle(fontSize: 12, color: secondary),
    // `outlined` flips the text to the secondary colour so the digit reads
    // against a transparent (outlined) background; otherwise the digit is
    // white over a filled/success background.
    circularStep: (outlined) => textTheme.bodySmall!.copyWith(
      height: 1.2,
      fontWeight: FontWeight.bold,
      color: outlined ? secondary : Colors.white,
    ),
  );

  final card = YiviCardStyles(
    notificationBody: textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      color: dark,
    ),
    quoteBody: textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    tileLabel: textButtonTextStyle.copyWith(
      fontWeight: FontWeight.w400,
      color: dark,
    ),
    actionBody: (color) => textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );

  final button = YiviButtonStyles(
    searchCancel: textButtonTextStyle.copyWith(
      fontWeight: FontWeight.normal,
      color: link,
    ),
    label: (color) => textTheme.labelLarge!.copyWith(color: color),
    smallLabel: (color) => textTheme.labelLarge!.copyWith(
      fontFamily: font,
      fontSize: 14,
      color: color,
    ),
  );

  final section = YiviSectionStyles(
    header: textTheme.headlineMedium!.copyWith(color: neutralExtraDark),
  );

  final requestor = YiviRequestorStyles(
    name: const TextStyle(
      fontFamily: font,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: dark,
      height: 26 / 19,
    ),
  );

  final bottomSheet = YiviBottomSheetStyles(
    title: const TextStyle(
      fontFamily: font,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: dark,
      height: 26 / 19,
    ),
  );

  final misc = YiviMiscStyles(
    avatarInitials: const TextStyle(
      fontWeight: FontWeight.bold,
      color: neutral,
    ),
    versionLabel: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600),
  );

  // ──────────────────────────────────────────────────────────────────────
  // Component themes — set defaults so widgets pick them up via Theme.of.
  // ──────────────────────────────────────────────────────────────────────
  final inputDecorationTheme = InputDecorationTheme(
    labelStyle: textTheme.labelSmall,
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: secondary, width: 2.0),
    ),
    errorBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: error, width: 2.0),
    ),
    disabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
    errorStyle: textTheme.bodyMedium?.copyWith(color: error),
  );

  final appBarTheme = AppBarTheme(
    backgroundColor: light,
    centerTitle: true,
    elevation: 0,
    iconTheme: const IconThemeData(color: dark),
    toolbarTextStyle: textTheme.bodyMedium,
    titleTextStyle: textTheme.displaySmall?.copyWith(color: dark),
    systemOverlayStyle: const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Toast / snackbar default — neutral dark-grey background, light text.
  // Call sites should not override these unless the toast needs to carry a
  // different status (e.g. an error toast, when we have one).
  final snackBarTheme = SnackBarThemeData(
    backgroundColor: secondary,
    contentTextStyle: textTheme.bodySmall!.copyWith(color: light),
    behavior: SnackBarBehavior.floating,
  );

  // Dialog default — surface-coloured card, large elevation, rounded
  // corners. Title and content styles are picked up by IrmaDialog and by
  // any future AlertDialog/SimpleDialog call site.
  final dialogTheme = DialogThemeData(
    backgroundColor: light,
    elevation: 24.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(smallSpacing),
    ),
    titleTextStyle: textTheme.displaySmall,
    contentTextStyle: textTheme.bodyMedium,
  );

  // ──────────────────────────────────────────────────────────────────────
  // Yivi-specific tokens that don't fit Material's standard ThemeData
  // shape — exposed via Theme.of(context).extension<YiviThemeExtension>()
  // (or the `context.yivi` getter).
  // ──────────────────────────────────────────────────────────────────────
  final yiviExtension = YiviThemeExtension(
    credential: credential,
    activity: activity,
    pin: pin,
    verification: verification,
    nfc: nfc,
    form: form,
    indicator: indicator,
    card: card,
    button: button,
    section: section,
    requestor: requestor,
    bottomSheet: bottomSheet,
    misc: misc,
    brand: const YiviBrandColors(
      success: success,
      successSurface: successSurface,
      warning: warning,
      link: link,
      danger: danger,
      neutral: neutral,
      neutralExtraLight: neutralExtraLight,
    ),
    tinySpacing: tinySpacing,
    smallSpacing: smallSpacing,
    defaultSpacing: defaultSpacing,
    mediumSpacing: mediumSpacing,
    largeSpacing: largeSpacing,
    hugeSpacing: hugeSpacing,
    screenPadding: screenPadding,
    borderRadius: borderRadius,
    textButtonTextStyle: textButtonTextStyle,
    hyperlinkTextStyle: hyperlinkTextStyle,
    mrzLabel: mrzLabel,
    font: font,
  );

  return ThemeData(
    fontFamily: font,
    scaffoldBackgroundColor: light,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
    ),
    colorScheme: colorScheme,
    textTheme: textTheme,
    appBarTheme: appBarTheme,
    inputDecorationTheme: inputDecorationTheme,
    snackBarTheme: snackBarTheme,
    dialogTheme: dialogTheme,
    extensions: [yiviExtension],
  );
}
