import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/dialog.dart";

/// Confirms a wipe with a dialog when it is first built, if the wallet was
/// deleted since the last enrollment screen. A dialog stays until the user
/// dismisses it, so they have the time to read it.
class WalletDeletedConfirmation extends StatefulWidget {
  final Widget child;

  const WalletDeletedConfirmation({super.key, required this.child});

  @override
  State<WalletDeletedConfirmation> createState() =>
      _WalletDeletedConfirmationState();
}

class _WalletDeletedConfirmationState extends State<WalletDeletedConfirmation> {
  @override
  void initState() {
    super.initState();

    // Post-frame: the navigator is only reachable once this subtree is mounted.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!repositoryOf(context).consumeWalletDeleted()) return;

      showDialog<void>(
        context: context,
        builder: (context) => YiviDialog(
          key: const Key("wallet_deleted_dialog"),
          title: context.tr("enrollment.wallet_deleted.title"),
          message: context.tr("enrollment.wallet_deleted.body"),
          actions: [
            PrimaryPillButton(
              label: context.tr("error.button_ok"),
              size: PillSize.regular,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
