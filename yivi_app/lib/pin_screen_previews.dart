// Widget previews for [YiviPinScreen] across its host configurations.
//
// Run with: `flutter widget-preview start` from `yivi_app/`.
//
// Scoping which previews load: the previewer discovers every `@Preview` in the
// project (here: these PIN previews + `credential_card_previews.dart`) and the
// CLI has no group/file filter. Within one run you can collapse/filter groups in
// the previewer UI. To launch with ONLY the PIN previews, hide the other preview
// file from the scan — the scanner ignores non-`.dart` files — then restore it
// (these files aren't imported by the app, so this is build-safe):
//
//   mv lib/credential_card_previews.dart{,.off}   # hide cards
//   flutter widget-preview start
//   mv lib/credential_card_previews.dart{.off,}   # restore when done
//
// (Add `*.dart.off` to .gitignore if you toggle often.)
//
// There is no seam to pre-fill the digit buffer, so each preview renders the
// empty state and you reach the interesting states by *typing* (on-screen pad
// or hardware keyboard):
//   - Choose/Onboarding short: type `12345` (ascending → insecure) to see the
//     warning text + the "Next" button appear in the reserved slot BELOW the
//     keypad. Type a secure 5-digit PIN to trigger auto-submit (no-op here).
//   - Choose/Onboarding long: the "Next" button is always in the bottom slot;
//     it enables once you reach 6 digits.
//   - Unlock short: nothing fills the bottom slot (auto-submit) — it shows the
//     reserved dead space at the bottom, the accepted trade-off of the
//     button-relocation change.
//
// The change-flow's "new PIN" step reuses the onboarding choose UI, so it is
// covered by the Choose previews. The distinct change screen is verify-old-PIN
// (plain entry), previewed under "Change / Reset".

import "package:flutter/material.dart";
import "package:flutter/widget_previews.dart";
// ignore_for_file: depend_on_referenced_packages, implementation_imports
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_i18n/loaders/decoders/json_decode_strategy.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:google_fonts/google_fonts.dart";

import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Preview scaffolding
// ─────────────────────────────────────────────────────────────────────────────

/// Phone-portrait canvas. Fixed so the PIN screen's `Expanded`-based layout has
/// a bounded, realistic viewport (and resolves to portrait orientation).
const pinPreviewSize = Size(390, 844);

/// Loads the real `yivi_core` translations from the asset bundle. Restricting
/// to JSON avoids three 404 probes per language (see card previews).
FlutterI18nDelegate _buildI18nDelegate() => FlutterI18nDelegate(
  translationLoader: FileTranslationLoader(
    basePath: "packages/yivi_core/assets/locales",
    fallbackFile: "en",
    forcedLocale: const Locale("en", "US"),
    decodeStrategies: [JsonDecodeStrategy()],
  ),
);

/// `IrmaTheme` uses the unqualified family names `Alexandria` / `Open Sans`;
/// the widget-preview scaffold doesn't reliably resolve the bundled fonts, so
/// we register them via Google Fonts (CDN) under those exact names. Failures
/// are swallowed so the previews still render (in the system font) when offline.
Future<void> _loadYiviFonts() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.alexandria(),
      GoogleFonts.openSans(),
    ]);
  } catch (_) {
    // Offline / CDN unavailable — fall back to the system font.
  }
  PaintingBinding.instance.handleSystemMessage(<String, Object?>{
    "type": "fontsChange",
  });
}

final Future<void> _fontsReady = _loadYiviFonts();

/// Wraps a preview in the theme + i18n + fonts stack the PIN screen needs, on a
/// full-screen (non-scrolling) phone-portrait canvas. Must be public so the
/// annotation can reference it.
Widget pinPreviewWrapper(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: [
    _buildI18nDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale("en", "US")],
  home: IrmaTheme(
    builder: (context) => MediaQuery(
      // Force portrait so the screen takes the `_bodyPortrait` path.
      data: const MediaQueryData(size: pinPreviewSize),
      child: FutureBuilder<void>(
        future: _fontsReady,
        builder: (context, snap) =>
            snap.connectionState == ConnectionState.done
            ? child
            : const SizedBox.shrink(),
      ),
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Stable scaffold keys — one per preview. `YiviPinScreen` force-unwraps
/// `scaffoldKey` when `checkSecurePin` is on (to host the warning bottom-sheet),
/// so it must be non-null and stable across rebuilds.
final _keys = {
  for (final id in [
    "chooseShort",
    "chooseLong",
    "unlockShort",
    "unlockLong",
    "session",
    "changeShort",
    "changeLong",
  ])
    id: GlobalKey<ScaffoldState>(debugLabel: id),
};

Widget _pin({
  required String keyId,
  required int maxPinSize,
  required String instructionKey,
  bool checkSecurePin = false,
  bool biometric = false,
  bool forgot = false,
  bool toggle = false,
}) {
  final scaffoldKey = _keys[keyId]!;
  final isLong = maxPinSize == longPinSize;
  return YiviPinScaffold(
    key: scaffoldKey,
    appBar: IrmaAppBar(titleString: ""),
    body: YiviPinScreen(
      scaffoldKey: scaffoldKey,
      instructionKey: instructionKey,
      maxPinSize: maxPinSize,
      onSubmit: (_) {},
      checkSecurePin: checkSecurePin,
      displayPinLength: checkSecurePin,
      onForgotPin: forgot ? () {} : null,
      onBiometricUnlock: biometric ? () {} : null,
      biometricGlyph: biometric ? const Icon(Icons.fingerprint, size: 28) : null,
      onTogglePinSize: toggle ? () {} : null,
      // Mirrors YiviChoosePinScaffold: keep the slot reserved (invisible) while
      // typing a short PIN, then reveal "Next" once it's long enough / insecure.
      submitButtonVisibilityListener: checkSecurePin
          ? (context, state) =>
                (!isLong && state.pin.length < shortPinSize)
                ? defaultSubmitButtonVisibility(context, maxPinSize)
                : WidgetVisibility.visible
          : null,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Group: Choose / Onboarding  (checkSecurePin + toggle + length counter)
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Choose / Onboarding",
  name: "short (5) — type 12345 for insecure",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewChooseShort() => _pin(
  keyId: "chooseShort",
  maxPinSize: shortPinSize,
  instructionKey: "choose_pin.instruction.short",
  checkSecurePin: true,
  toggle: true,
);

@Preview(
  group: "Choose / Onboarding",
  name: "long (16)",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewChooseLong() => _pin(
  keyId: "chooseLong",
  maxPinSize: longPinSize,
  instructionKey: "choose_pin.instruction.long",
  checkSecurePin: true,
  toggle: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Unlock  (biometric glyph in keypad + "forgot PIN" link)
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Unlock",
  name: "short (5) + biometric — bottom slot is dead space",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewUnlockShort() => _pin(
  keyId: "unlockShort",
  maxPinSize: shortPinSize,
  instructionKey: "pin.subtitle",
  biometric: true,
  forgot: true,
);

@Preview(
  group: "Unlock",
  name: "long (16) + biometric",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewUnlockLong() => _pin(
  keyId: "unlockLong",
  maxPinSize: longPinSize,
  instructionKey: "pin.subtitle",
  biometric: true,
  forgot: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Session  (plain entry — no biometric, no forgot, no toggle)
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Session",
  name: "short (5)",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewSession() => _pin(
  keyId: "session",
  maxPinSize: shortPinSize,
  instructionKey: "pin.subtitle",
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Change / Reset  (verify-old-PIN step — plain entry + forgot link;
// the new-PIN step is identical to the Choose previews above)
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Change / Reset",
  name: "verify old PIN — short (5)",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewChangeShort() => _pin(
  keyId: "changeShort",
  maxPinSize: shortPinSize,
  instructionKey: "change_pin.enter_pin.instruction",
  forgot: true,
);

@Preview(
  group: "Change / Reset",
  name: "verify old PIN — long (16)",
  wrapper: pinPreviewWrapper,
  size: pinPreviewSize,
)
Widget previewChangeLong() => _pin(
  keyId: "changeLong",
  maxPinSize: longPinSize,
  instructionKey: "change_pin.enter_pin.instruction",
  forgot: true,
);
