import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/translated_text.dart";
import "../../scanner/util/camera_access.dart";
import "document_instruction_screen.dart" show DocumentTipBox;
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "widgets/document_camera_frame.dart";
import "widgets/document_flow_footer.dart";
import "widgets/mrz_scanner.dart";

/// Reads the MRZ of a document with the camera.
class MrzReaderScreen extends ConsumerStatefulWidget {
  final void Function(MrzResult mrzResult) onSuccess;
  final VoidCallback onManualAdd;
  final MrzParser mrzParser;

  /// The document: its scan title, "Enter manually" and its instruction
  /// ("Open your passport on …", its tip), which the camera step says
  /// beside the camera in a sheet held sideways.
  final DocumentType documentType;

  const MrzReaderScreen({
    required this.documentType,
    required this.onSuccess,
    required this.onManualAdd,
    required this.mrzParser,
  });

  @override
  ConsumerState<MrzReaderScreen> createState() => MrzReaderScreenState();
}

class MrzReaderScreenState extends ConsumerState<MrzReaderScreen> {
  // One scanner across the portrait and landscape layouts: the key keeps its
  // state (and the camera) when the device turns.
  final _scannerKey = GlobalKey<MrzScannerState>();

  @override
  Widget build(BuildContext context) {
    // While it is looked up the dark card shows, without words. In
    // integration tests there is no camera: the fallback shows.
    final body = CameraAccessBuilder(
      inTests: CameraAccess.denied,
      builder: (context, access) => switch (access) {
        null => const SizedBox.shrink(),
        CameraAccess.granted => MrzScanner(
          key: _scannerKey,
          onSuccess: widget.onSuccess,
          mrzParser: widget.mrzParser,
        ),
        _ => const _DarkPermissionFallback(),
      },
    );

    // As on the canvas: the picture in a rounded card under the sheet's
    // bar, "Enter manually" under it, no Cancel.
    return _SheetCamera(
      titleKey: widget.documentType.scanTitleKey,
      body: body,
      manualLabel: widget.documentType.scanManualKey,
      onManual: widget.onManualAdd,
      instructionKey: widget.documentType.instructionKey,
    );
  }
}

/// The camera as a step in a sheet: the picture in a rounded card filling
/// the page under the sheet's bar, and "Enter manually" under it.
class _SheetCamera extends StatelessWidget {
  /// The page's heading upright ("Scan passport"), above the camera.
  final String titleKey;
  final Widget body;
  final String manualLabel;
  final VoidCallback onManual;

  /// What to do, beside the camera held sideways (`.title` and `.tip`).
  final String instructionKey;

  const _SheetCamera({
    required this.titleKey,
    required this.body,
    required this.manualLabel,
    required this.onManual,
    required this.instructionKey,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: YiviCorners.cardRadius,
      child: ColoredBox(color: cameraDark, child: body),
    );
    // The camera moves on by itself: no way on, only "Enter manually", the
    // other choice. Upright in a sheet it is in the page's bottom bar, which
    // stays put; with the way on in the sheet's bar, a link.
    if (SheetSlotAction.atBottom(context)) {
      return SheetSlotAction(
        action: null,
        secondary: SheetAction(
          key: DocumentFlowButton.primaryKey,
          label: context.tr(manualLabel),
          onTap: onManual,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x16,
            YiviSpace.x8,
            YiviSpace.x16,
            YiviSpace.x8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The page's heading, as on every step of adding a card.
              DocumentSheetHeading(
                titleKey,
                textKey: const Key("sheet_camera_heading"),
              ),
              Expanded(child: card),
            ],
          ),
        ),
      );
    }
    final inBar = GlassSheet.actionInBar(context);
    final Widget manual = inBar
        ? SheetSlotAction(
            action: null,
            child: Center(
              child: TextLink(
                key: DocumentFlowButton.primaryKey,
                label: context.tr(manualLabel),
                onPressed: onManual,
              ),
            ),
          )
        : PillButton(
            key: DocumentFlowButton.primaryKey,
            label: context.tr(manualLabel),
            onPressed: onManual,
          );
    // Held sideways: what to do and "Enter manually" at the left, the
    // camera at the right.
    if (useSheetColumns(context)) {
      return SheetSplit(
        endFills: true,
        start: [
          TranslatedText(
            "$instructionKey.title",
            isHeader: true,
            style: documentSplitHeadingStyle(YiviPalette.of(context)),
          ),
          DocumentTipBox(textKey: "$instructionKey.tip"),
        ],
        end: card,
        actions: manual,
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        YiviSpace.x16,
        YiviSpace.x8,
        YiviSpace.x16,
        FloatingBarPlacement.buttonBottom(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x12,
        children: [
          Expanded(child: card),
          manual,
        ],
      ),
    );
  }
}

/// Without camera permission, on the dark camera card: what to do, in
/// white.
class _DarkPermissionFallback extends ConsumerWidget {
  const _DarkPermissionFallback();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          YiviSpace.x32,
          padding.top + 84,
          YiviSpace.x32,
          padding.bottom + 180,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: YiviSpace.x12,
          children: [
            TranslatedText(
              "mrz_camera_permissions.title",
              isHeader: true,
              textAlign: TextAlign.center,
              style: palette.titleCompact.copyWith(color: Colors.white),
            ),
            TranslatedText(
              "mrz_camera_permissions.content",
              textAlign: TextAlign.center,
              style: palette
                  .body(16)
                  .copyWith(height: 24 / 16, color: const Color(0xD9FFFFFF)),
            ),
            TextLink(
              label: context.tr("mrz_camera_permissions.open_settings"),
              color: Colors.white,
              // The camera stays, and looks again when the app comes back.
              onPressed: () =>
                  ref.read(cameraPermissionProvider).openSettings(),
            ),
          ],
        ),
      ),
    );
  }
}
