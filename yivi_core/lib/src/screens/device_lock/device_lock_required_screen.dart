import "dart:io";

import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/feedback/status_screen.dart";

/// Shown instead of the app while the device has no screen lock. There is no way
/// past it in a release build: the user sets a screen lock and comes back.
class DeviceLockRequiredScreen extends StatelessWidget {
  final VoidCallback onOpenSettingsPressed;
  final VoidCallback onCheckAgainPressed;

  /// Debug builds only, see DeviceLockRequirement.skipForDebugging.
  final VoidCallback? onContinueAnywayPressed;

  const DeviceLockRequiredScreen({
    super.key,
    required this.onOpenSettingsPressed,
    required this.onCheckAgainPressed,
    this.onContinueAnywayPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Android can open the screen lock settings; iOS has no public way to, so
    // there the explanation says where to go and the button checks again.
    final canOpenSettings = Platform.isAndroid;
    final skip = kDebugMode ? onContinueAnywayPressed : null;
    return PopScope(
      canPop: false,
      child: StatusScreen(
        key: const Key("device_lock_required"),
        icon: Icons.lock_outline_rounded,
        tone: YiviTone.warning,
        title: context.tr("device_lock_required.title"),
        message: context.tr(
          canOpenSettings
              ? "device_lock_required.explanation_android"
              : "device_lock_required.explanation_ios",
        ),
        actions: ActionBar(
          key: const Key("device_lock_required_bottom_bar"),
          actions: [
            ActionBar.primary(
              label: context.tr(
                canOpenSettings
                    ? "device_lock_required.open_settings"
                    : "device_lock_required.check_again",
              ),
              onTap: canOpenSettings
                  ? onOpenSettingsPressed
                  : onCheckAgainPressed,
            ),
            if (skip != null)
              ActionBar.secondary(
                label: context.tr(
                  "device_lock_required.continue_anyway_debug",
                ),
                onTap: skip,
              ),
          ],
        ),
      ),
    );
  }
}
