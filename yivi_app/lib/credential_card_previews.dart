// Widget previews for [YiviCredentialCard].
//
// Run with: `flutter widget-preview start` from `yivi_app/`.
//
// Most scenarios here focus on the attribute-list rendering rules — in
// particular, how the card behaves for arrays / nested objects with and
// without an explicit header attribute, and how `effectiveDisplayName` falls
// back when the backend did not supply a `displayName`.

import "package:flutter/material.dart";
import "package:flutter/widget_previews.dart";
// ignore_for_file: depend_on_referenced_packages, implementation_imports
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_i18n/loaders/decoders/json_decode_strategy.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";

import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Preview scaffolding
// ─────────────────────────────────────────────────────────────────────────────

/// Loads the real `yivi_core` translations from the asset bundle.
///
/// [FileTranslationLoader] probes every supported extension in parallel
/// (`.json`, `.yaml`, `.xml`, `.toml`); without `decodeStrategies` you get
/// three guaranteed 404s per language load. Restricting to JSON keeps the
/// console clean.
FlutterI18nDelegate _buildI18nDelegate() => FlutterI18nDelegate(
  translationLoader: FileTranslationLoader(
    basePath: "packages/yivi_core/assets/locales",
    fallbackFile: "en",
    forcedLocale: const Locale("en", "US"),
    decodeStrategies: [JsonDecodeStrategy()],
  ),
);

/// Default canvas size for every preview. Picking one fixed size makes the
/// gallery tile previews side-by-side instead of stretching to fit, which is
/// what makes cross-preview comparison useful.
const yiviCardPreviewSize = Size(380, 640);

/// A single Riverpod container shared by every preview.
final _previewProviderContainer = ProviderContainer();

/// Loads the `yivi_core` fonts at runtime via [FontLoader]. The widget-preview
/// tool generates a scaffold project that registers yivi_core's fonts only
/// under the package-prefixed names (`packages/yivi_core/Alexandria` etc.),
/// but `IrmaTheme` uses the unqualified family names. We register them under
/// the unqualified names here.
///
/// The font files are accessible at runtime via these `packages/yivi_core/...`
/// paths because yivi_core's pubspec declares `fonts/alexandria/`,
/// `fonts/open-sans/`, and `fonts/irma-icons/` in its `assets:` section.
/// Result of the font registration pass. Reported on-screen so we don't have
/// to chase terminal output.
class _FontLoadReport {
  final List<String> registered = [];
  final List<String> failed = [];
}

/// Loads Alexandria + Open Sans from Google Fonts (CDN) at runtime. Internally,
/// `google_fonts` calls `FontLoader` with `Alexandria` / `Open Sans` as the
/// family names, which is exactly what `IrmaTheme` looks up. The bundled-font
/// path under `flutter widget-preview` doesn't reliably resolve, so we go via
/// the CDN here.
///
/// IrmaIcons is bundled-only — no Google Fonts equivalent — so icon glyphs in
/// the preview will fall back to system rendering. None of the credential-card
/// previews actually use IrmaIcons glyphs, so this is fine.
Future<_FontLoadReport> _loadYiviFonts() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  final report = _FontLoadReport();
  final loads = <String, Future<void>>{
    "Alexandria": GoogleFonts.pendingFonts([GoogleFonts.alexandria()]),
    "Open Sans": GoogleFonts.pendingFonts([GoogleFonts.openSans()]),
  };
  for (final entry in loads.entries) {
    try {
      await entry.value;
      report.registered.add(entry.key);
    } catch (e) {
      report.failed.add("${entry.key}: $e");
    }
  }
  // Force any text widgets that were already laid out to relayout with the
  // newly-registered fonts.
  PaintingBinding.instance.handleSystemMessage(<String, Object?>{
    "type": "fontsChange",
  });
  return report;
}

final Future<_FontLoadReport> _fontsReady = _loadYiviFonts();

/// Riverpod 3.x (both 3.2 and 3.3) schedules an unconditional post-frame
/// `setState({})` from `_UncontrolledProviderScopeState.build` with no
/// `mounted` guard. The preview runner mounts/unmounts previews as the user
/// navigates, so the post-frame fires after dispose and trips a
/// `setState() called after dispose()` assertion. The previews render fine —
/// the noise just floods the console. Filter that one specific assertion at
/// startup and forward everything else.
final _suppressRiverpodDisposeNoise = () {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains("setState() called after dispose()") &&
        msg.contains("_UncontrolledProviderScopeState")) {
      return;
    }
    (original ?? FlutterError.presentError)(details);
  };
  return true;
}();

/// Wraps a preview in the providers/theme/i18n stack the card needs. Must be
/// a public top-level function so the preview annotation can reference it.
Widget yiviCardPreviewWrapper(Widget child) {
  // Touch the lazy initializer so the error filter installs on first use.
  // ignore: unnecessary_statements
  _suppressRiverpodDisposeNoise;
  return UncontrolledProviderScope(
    container: _previewProviderContainer,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        _buildI18nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale("en", "US")],
      home: IrmaTheme(
        builder: (context) {
          final theme = IrmaTheme.of(context);
          return Scaffold(
            backgroundColor: theme.light,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(theme.defaultSpacing),
                // Hold rendering until the yivi fonts are registered so the
                // card doesn't briefly flash in the system font.
                child: FutureBuilder<_FontLoadReport>(
                  future: _fontsReady,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    final report = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report != null && report.failed.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Font load FAILED: ${report.failed.join(' | ')}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB00020),
                              ),
                            ),
                          ),
                        child,
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixture helpers
// ─────────────────────────────────────────────────────────────────────────────

TrustedParty _demoIssuer() => TrustedParty(
  id: "irma-demo.MijnOverheid",
  name: TranslatedValue({"en": "Demo MijnOverheid"}),
  url: null,
  parent: null,
  verified: true,
);

/// Builds an `Attribute` with a value. Pass `displayName: ""` to exercise the
/// `effectiveDisplayName` fallback path.
Attribute _leaf({
  required List<dynamic> claimPath,
  String displayName = "",
  String? stringValue,
  bool? boolValue,
  int? intValue,
}) {
  final dn = displayName.isEmpty
      ? const TranslatedValue.empty()
      : TranslatedValue({"en": displayName});
  AttributeValue? value;
  if (stringValue != null) {
    value = AttributeValue(type: AttributeType.string, string: stringValue);
  } else if (boolValue != null) {
    value = AttributeValue(type: AttributeType.boolean, boolValue: boolValue);
  } else if (intValue != null) {
    value = AttributeValue(type: AttributeType.integer, intValue: intValue);
  }
  return Attribute(claimPath: claimPath, displayName: dn, value: value);
}

/// Builds a *header* attribute (value == null). Headers anchor the
/// labels for groups and arrays in the attribute tree.
Attribute _header({required List<dynamic> claimPath, String displayName = ""}) {
  final dn = displayName.isEmpty
      ? const TranslatedValue.empty()
      : TranslatedValue({"en": displayName});
  return Attribute(claimPath: claimPath, displayName: dn);
}

YiviCredentialCard _card({
  required List<Attribute> attributes,
  String name = "Demo Credential",
  IrmaCardStyle style = IrmaCardStyle.normal,
  bool revoked = false,
  int? expiryDateUnix,
  Map<CredentialFormat, int?> batchCounts = const {},
  TranslatedValue? issueUrl,
  bool hideFooter = true,
}) {
  return YiviCredentialCard(
    credentialName: TranslatedValue({"en": name}),
    issuerName: _demoIssuer().name,
    attributes: attributes,
    status: CredentialCardStatus(
      revoked: revoked,
      expiryDateUnix: expiryDateUnix,
      batchInstanceCountsRemaining: batchCounts,
      credentialId: "irma-demo.MijnOverheid.root",
      issueUrl: issueUrl,
    ),
    compact: false,
    style: style,
    hideFooter: hideFooter,
  );
}

// Returns a unix timestamp `days` days from now. Computed at call time so the
// previews stay accurate as time passes.
int _unixDaysFromNow(int days) =>
    DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch ~/ 1000;

// ─────────────────────────────────────────────────────────────────────────────
// Group: Basic attributes
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Basics",
  name: "Simple attributes",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewSimpleAttributes() => _card(
  attributes: [
    _leaf(
      claimPath: const ["bsn"],
      displayName: "BSN",
      stringValue: "999999990",
    ),
    _leaf(
      claimPath: const ["firstname"],
      displayName: "First name",
      stringValue: "Willeke",
    ),
    _leaf(
      claimPath: const ["familyname"],
      displayName: "Family name",
      stringValue: "Bruijn",
    ),
  ],
);

@Preview(
  group: "Basics",
  name: "Boolean Yes/No",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewBooleanAttributes() => _card(
  attributes: [
    _leaf(claimPath: const ["over18"], displayName: "Over 18", boolValue: true),
    _leaf(
      claimPath: const ["over65"],
      displayName: "Over 65",
      boolValue: false,
    ),
  ],
);

@Preview(
  group: "Basics",
  name: "Mixed types",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewMixedTypes() => _card(
  attributes: [
    _leaf(
      claimPath: const ["name"],
      displayName: "Name",
      stringValue: "Willeke",
    ),
    _leaf(claimPath: const ["age"], displayName: "Age", intValue: 42),
    _leaf(claimPath: const ["over18"], displayName: "Over 18", boolValue: true),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: effectiveDisplayName fallback
//
// These exercise the new `effectiveDisplayName` getter introduced in the
// PR. Compare these against the "Basics" group to see how missing
// `displayName` labels get filled in from `claimPath`.
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Fallback",
  name: "Top-level: no displayName",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewTopLevelNoDisplayName() => _card(
  attributes: [
    _leaf(claimPath: const ["firstname"], stringValue: "Willeke"),
    _leaf(claimPath: const ["familyname"], stringValue: "Bruijn"),
  ],
);

@Preview(
  group: "Fallback",
  name: "Top-level: all-int claim path",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewAllIntClaimPath() => _card(
  attributes: [
    // Last-resort fallback: `claimPath.join(".")` → "0".
    _leaf(claimPath: const [0], stringValue: "weird"),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Primitive arrays — with vs. without explicit header attribute
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Prim arrays",
  name: "WITH explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewPrimArrayWithHeader() => _card(
  attributes: [
    _header(claimPath: const ["tags"], displayName: "Tags"),
    _leaf(claimPath: const ["tags", 0], stringValue: "red"),
    _leaf(claimPath: const ["tags", 1], stringValue: "green"),
    _leaf(claimPath: const ["tags", 2], stringValue: "blue"),
  ],
);

@Preview(
  group: "Prim arrays",
  name: "WITHOUT explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewPrimArrayWithoutHeader() => _card(
  attributes: [
    // No `["tags"]` header attribute. Pre-PR this rendered with an empty
    // label (effectively no header); after the PR the label falls back to
    // "tags" from the claim path.
    _leaf(claimPath: const ["tags", 0], stringValue: "red"),
    _leaf(claimPath: const ["tags", 1], stringValue: "green"),
    _leaf(claimPath: const ["tags", 2], stringValue: "blue"),
  ],
);

@Preview(
  group: "Prim arrays",
  name: "WITH header, empty displayName",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewPrimArrayHeaderEmptyDisplayName() => _card(
  attributes: [
    // Header is present but its `displayName` is empty. After the PR this
    // still falls back to "tags" because the header itself uses
    // `effectiveDisplayName`.
    _header(claimPath: const ["tags"]),
    _leaf(claimPath: const ["tags", 0], stringValue: "red"),
    _leaf(claimPath: const ["tags", 1], stringValue: "green"),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Object arrays — with vs. without explicit header attribute
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Object arrays",
  name: "WITH explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewObjectArrayWithHeader() => _card(
  attributes: [
    _header(claimPath: const ["addresses"], displayName: "Addresses"),
    _leaf(
      claimPath: const ["addresses", 0, "street"],
      displayName: "Street",
      stringValue: "Meander",
    ),
    _leaf(
      claimPath: const ["addresses", 0, "city"],
      displayName: "City",
      stringValue: "Arnhem",
    ),
    _leaf(
      claimPath: const ["addresses", 1, "street"],
      displayName: "Street",
      stringValue: "Hoofdweg",
    ),
    _leaf(
      claimPath: const ["addresses", 1, "city"],
      displayName: "City",
      stringValue: "Amsterdam",
    ),
  ],
);

@Preview(
  group: "Object arrays",
  name: "WITHOUT explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewObjectArrayWithoutHeader() => _card(
  attributes: [
    // No `["addresses"]` header. The per-item eyebrow falls back to "ITEM"
    // because `parentHeader` is null. Compare with the previous preview.
    _leaf(
      claimPath: const ["addresses", 0, "street"],
      displayName: "Street",
      stringValue: "Meander",
    ),
    _leaf(
      claimPath: const ["addresses", 0, "city"],
      displayName: "City",
      stringValue: "Arnhem",
    ),
    _leaf(
      claimPath: const ["addresses", 1, "street"],
      displayName: "Street",
      stringValue: "Hoofdweg",
    ),
    _leaf(
      claimPath: const ["addresses", 1, "city"],
      displayName: "City",
      stringValue: "Amsterdam",
    ),
  ],
);

@Preview(
  group: "Object arrays",
  name: "Child leaves WITHOUT displayName",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewObjectArrayChildrenNoDisplayName() => _card(
  attributes: [
    _header(claimPath: const ["addresses"], displayName: "Addresses"),
    // Leaves have empty displayName — after the PR they show "street" /
    // "city" derived from the claim path. Pre-PR they rendered blank.
    _leaf(claimPath: const ["addresses", 0, "street"], stringValue: "Meander"),
    _leaf(claimPath: const ["addresses", 0, "city"], stringValue: "Arnhem"),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Nested objects (no array indices)
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "Nested objects",
  name: "WITH explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewNestedObjectWithHeader() => _card(
  attributes: [
    _header(claimPath: const ["address"], displayName: "Address"),
    _leaf(
      claimPath: const ["address", "street"],
      displayName: "Street",
      stringValue: "Meander",
    ),
    _leaf(
      claimPath: const ["address", "city"],
      displayName: "City",
      stringValue: "Arnhem",
    ),
  ],
);

@Preview(
  group: "Nested objects",
  name: "WITHOUT explicit header",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewNestedObjectWithoutHeader() => _card(
  attributes: [
    // No `["address"]` header. With no header attribute the tree builder
    // doesn't synthesise a group — the leaves render side-by-side.
    _leaf(
      claimPath: const ["address", "street"],
      displayName: "Street",
      stringValue: "Meander",
    ),
    _leaf(
      claimPath: const ["address", "city"],
      displayName: "City",
      stringValue: "Arnhem",
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Card visual states
// ─────────────────────────────────────────────────────────────────────────────

@Preview(
  group: "States",
  name: "Normal",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewStateNormal() => _card(
  attributes: [
    _leaf(
      claimPath: const ["bsn"],
      displayName: "BSN",
      stringValue: "999999990",
    ),
  ],
);

@Preview(
  group: "States",
  name: "Highlighted",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewStateHighlighted() => _card(
  attributes: [
    _leaf(
      claimPath: const ["bsn"],
      displayName: "BSN",
      stringValue: "999999990",
    ),
  ],
  style: IrmaCardStyle.highlighted,
);

@Preview(
  group: "States",
  name: "Revoked",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewStateRevoked() => _card(
  attributes: [
    _leaf(
      claimPath: const ["bsn"],
      displayName: "BSN",
      stringValue: "999999990",
    ),
  ],
  revoked: true,
);

@Preview(
  group: "States",
  name: "Expired",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewStateExpired() => _card(
  attributes: [
    _leaf(
      claimPath: const ["bsn"],
      displayName: "BSN",
      stringValue: "999999990",
    ),
  ],
  // ~Jan 2024 — well in the past.
  expiryDateUnix: 1704067200,
);

// ─────────────────────────────────────────────────────────────────────────────
// Group: Card footer
//
// The footer shows two cells: "Valid until <date>" and "Sharable" (with a
// count or "unlimited"). The text colour switches to warning / error as the
// time- and instance-expire states tip over the thresholds.
// ─────────────────────────────────────────────────────────────────────────────

List<Attribute> _footerAttrs() => [
  _leaf(claimPath: const ["bsn"], displayName: "BSN", stringValue: "999999990"),
];

@Preview(
  group: "Footer",
  name: "Valid, unlimited sharable",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterValidUnlimited() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(365),
  // Empty batchCounts → instanceCount stays null → "Sharable unlimited".
  batchCounts: const {},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Valid, N sharable",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterValidCount() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(365),
  batchCounts: const {CredentialFormat.idemix: 42},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Valid, low sharable (warning)",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterLowCount() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(365),
  // Default threshold is 5 → 3 is "almostExpired" → warning colour.
  batchCounts: const {CredentialFormat.idemix: 3},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Valid, zero sharable (expired count)",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterZeroCount() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(365),
  // instanceCount <= 0 → expired → card flips to danger style.
  batchCounts: const {CredentialFormat.idemix: 0},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Expiring soon (≤ 7 days)",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterExpiringSoon() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(3),
  batchCounts: const {CredentialFormat.idemix: 42},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Expired date",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterExpiredDate() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(-30),
  batchCounts: const {CredentialFormat.idemix: 42},
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Expiring soon, reobtain button",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterReobtainButton() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(3),
  batchCounts: const {CredentialFormat.idemix: 42},
  // Adding a non-empty issueUrl flips `showReobtain` on once the credential
  // is expiring/expired/revoked.
  issueUrl: TranslatedValue({"en": "https://example.invalid/reobtain"}),
  hideFooter: false,
);

@Preview(
  group: "Footer",
  name: "Worst case: expired + zero count + reobtain",
  wrapper: yiviCardPreviewWrapper,
  size: yiviCardPreviewSize,
)
Widget previewFooterWorstCase() => _card(
  attributes: _footerAttrs(),
  expiryDateUnix: _unixDaysFromNow(-30),
  batchCounts: const {CredentialFormat.idemix: 0},
  issueUrl: TranslatedValue({"en": "https://example.invalid/reobtain"}),
  hideFooter: false,
);
