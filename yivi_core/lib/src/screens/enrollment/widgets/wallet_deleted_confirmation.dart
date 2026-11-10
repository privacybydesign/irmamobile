import "package:flutter/scheduler.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/yivi_themed_button.dart";

/// Confirms a wipe with a dialog when it is first built, if the wallet was
/// deleted since the last enrollment screen. A dialog stays until the user
/// dismisses it, so they have the time to read it.
class WalletDeletedConfirmation extends StatefulWidget {
  final Widget child;

  const WalletDeletedConfirmation({required this.child});

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
      if (!IrmaRepositoryProvider.of(context).consumeWalletDeleted()) return;

      showDialog<void>(
        context: context,
        builder: (context) => IrmaDialog(
          title: FlutterI18n.translate(
            context,
            "enrollment.wallet_deleted.title",
          ),
          content: FlutterI18n.translate(
            context,
            "enrollment.wallet_deleted.body",
          ),
          child: YiviThemedButton(
            label: "error.button_ok",
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
