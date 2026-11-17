import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";

/// Where the scanner is: looking, read a Yivi QR code, or read another code.
enum ScanState { scanning, found, error }

/// What the scanner says, as a pill on the camera under the window: white
/// (black in the dark theme), the instruction while it looks, green or red
/// after a code, with an icon before it.
class ScanPill extends StatelessWidget {
  final ScanState state;

  const ScanPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (key, icon, colour) = switch (state) {
      ScanState.scanning => (
        "qr_scanner.instruction.message",
        CupertinoIcons.qrcode_viewfinder,
        palette.text,
      ),
      ScanState.found => (
        "qr_scanner.success.message",
        CupertinoIcons.checkmark_circle_fill,
        palette.successText,
      ),
      ScanState.error => (
        "qr_scanner.error.message",
        CupertinoIcons.xmark_circle_fill,
        palette.errorText,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        key: const Key("qr_scanner_status"),
        decoration: BoxDecoration(
          color: palette.isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.35 : 0.22,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: YiviSpace.x16,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colour),
                const SizedBox(width: YiviSpace.x8),
                Flexible(
                  child: Text(
                    context.tr(key),
                    textAlign: TextAlign.center,
                    style: palette
                        .body(15, weight: FontWeight.w600)
                        .copyWith(color: colour, height: 20 / 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
