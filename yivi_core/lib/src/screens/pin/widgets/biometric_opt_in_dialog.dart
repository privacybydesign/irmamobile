import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../theme/theme.dart";
import "../../../widgets/yivi_dialog.dart";
import "../../../widgets/yivi_themed_button.dart";
import "../providers/biometric_provider.dart";

/// One-time biometric opt-in, shown during enrollment (after the PIN is
/// confirmed) and as the post-unlock prompt. Tapping Enable first confirms with
/// a real biometric prompt and only persists `enabled = true` on success;
/// failure/cancel leaves both prefs untouched (so the prompt can re-appear).
/// Not now records a deliberate decline. Non-dismissible — the user picks one.
Future<void> showBiometricOptInDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _BiometricOptInDialog(),
  );
}

class _BiometricOptInDialog extends ConsumerStatefulWidget {
  const _BiometricOptInDialog();

  @override
  ConsumerState<_BiometricOptInDialog> createState() =>
      _BiometricOptInDialogState();
}

class _BiometricOptInDialogState extends ConsumerState<_BiometricOptInDialog> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    final service = ref.read(biometricServiceProvider);
    final ok = await service.authenticate(
      localizedReason: FlutterI18n.translate(
        context,
        "pin.biometric_confirm_reason",
      ),
    );
    if (ok) {
      // Persist in the background (the pref's in-memory value updates
      // synchronously); closing the dialog shouldn't block on disk I/O.
      unawaited(service.setEnabled(true));
      unawaited(service.dismissPrompt());
    }
    // Success or failure, the question is answered for now: close. On failure
    // `dismissed` stays unset, so the prompt can re-appear at the next lock.
    if (mounted) Navigator.of(context).pop();
  }

  void _notNow() {
    ref.read(biometricServiceProvider).dismissPrompt();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return YiviDialog.structured(
      title: FlutterI18n.translate(context, "pin.biometric_prompt.title"),
      content: FlutterI18n.translate(context, "pin.biometric_prompt.body"),
      child: Column(
        children: [
          YiviThemedButton(
            key: const Key("biometric_enable"),
            label: "pin.biometric_prompt.enable",
            onPressed: _busy ? null : _enable,
          ),
          SizedBox(height: context.yivi.spacing.small),
          YiviThemedButton(
            key: const Key("biometric_not_now"),
            label: "pin.biometric_prompt.not_now",
            style: YiviButtonStyle.outlined,
            onPressed: _busy ? null : _notNow,
          ),
        ],
      ),
    );
  }
}
