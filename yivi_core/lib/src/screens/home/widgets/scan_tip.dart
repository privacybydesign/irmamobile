import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/preferences_provider.dart";
import "../../../providers/schemaless_credentials_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/translated_text.dart";

final _scanTipPendingProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getScanTipPending(),
);

/// Whether the tip on the Scan button shows: on the first visit after the
/// enrollment, until "Got it" or until there is data.
final scanTipVisibleProvider = Provider<bool>((ref) {
  final pending = ref.watch(_scanTipPendingProvider).value ?? false;
  return pending && !ref.watch(hasCredentialsProvider);
});

/// The first time the app opens empty: where to scan a QR code. It sits
/// next to the Scan button: above it on the tab bar, beside it on the rail.
class ScanTip extends ConsumerWidget {
  /// Beside the rail's Scan button, rather than above the tab bar's.
  final bool rail;

  const ScanTip({super.key, required this.rail});

  static const double width = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    return SizedBox(
      width: width,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: GlassSurface(
          key: const Key("scan_tip"),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(YiviCorners.sheet)),
          ),
          fill: palette.glassStrongFill,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText(
                "scan_tip.title",
                style: palette
                    .body(14.5, weight: FontWeight.w700)
                    .copyWith(color: palette.heading),
              ),
              const SizedBox(height: 2),
              TranslatedText(
                rail ? "scan_tip.text_rail" : "scan_tip.text_bar",
                style: palette.body(13).copyWith(color: palette.secondaryText),
              ),
              const SizedBox(height: 8),
              SmallPill(
                key: const Key("scan_tip_ok"),
                label: FlutterI18n.translate(context, "scan_tip.ok"),
                onPressed: () =>
                    ref.read(preferencesProvider).markScanTipShown(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
