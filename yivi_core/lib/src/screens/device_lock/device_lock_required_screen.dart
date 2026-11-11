import "dart:io";

import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

/// Shown instead of the app while the device has no screen lock. There is no way
/// past it in a release build: the user sets a screen lock and comes back.
class DeviceLockRequiredScreen extends StatelessWidget {
  final VoidCallback onOpenSettingsPressed;
  final VoidCallback onCheckAgainPressed;

  /// Debug builds only, see DeviceLockRequirement.skipForDebugging.
  final VoidCallback? onContinueAnywayPressed;

  const DeviceLockRequiredScreen({
    required this.onOpenSettingsPressed,
    required this.onCheckAgainPressed,
    this.onContinueAnywayPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Android can open the screen lock settings; iOS has no public way to, so
    // there the explanation says where to go and the button checks again.
    final canOpenSettings = Platform.isAndroid;
    return Scaffold(
      body: IrmaInfoScaffoldBody(
        imagePath: yiviAsset("error/insecure_device_illustration.svg"),
        titleTranslationKey: "device_lock_required.title",
        bodyTranslationKey: canOpenSettings
            ? "device_lock_required.explanation_android"
            : "device_lock_required.explanation_ios",
      ),
      bottomNavigationBar: IrmaBottomBar(
        key: const Key("device_lock_required_bottom_bar"),
        primaryButtonLabel: canOpenSettings
            ? "device_lock_required.open_settings"
            : "device_lock_required.check_again",
        onPrimaryPressed: canOpenSettings
            ? onOpenSettingsPressed
            : onCheckAgainPressed,
        secondaryButtonLabel: kDebugMode && onContinueAnywayPressed != null
            ? "device_lock_required.continue_anyway_debug"
            : null,
        onSecondaryPressed: kDebugMode ? onContinueAnywayPressed : null,
      ),
    );
  }
}
