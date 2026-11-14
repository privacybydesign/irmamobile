import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_tone.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
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
    await ref
        .read(biometricServiceProvider)
        .confirmAndEnable(
          localizedReason: context.tr("pin.biometric_confirm_reason"),
        );
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
    return GlassDialog(
      icon: const ToneDisc(icon: Icons.fingerprint, tone: YiviTone.info),
      title: context.tr("pin.biometric_prompt.title"),
      message: context.tr("pin.biometric_prompt.body"),
      actions: [
        FancyPillButton(
          key: const Key("biometric_enable"),
          label: context.tr("pin.biometric_prompt.enable"),
          size: PillSize.regular,
          onPressed: _busy ? null : _enable,
        ),
        PillButton(
          key: const Key("biometric_not_now"),
          label: context.tr("pin.biometric_prompt.not_now"),
          style: PillStyle.text,
          size: PillSize.regular,
          onPressed: _busy ? null : _notNow,
        ),
      ],
    );
  }
}
