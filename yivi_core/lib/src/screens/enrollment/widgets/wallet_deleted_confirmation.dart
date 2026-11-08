import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";

/// Confirms a wipe with a snackbar when it is first built, if the wallet was
/// deleted since the last enrollment screen.
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

    // Post-frame: the messenger is only reachable once this subtree is mounted.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!IrmaRepositoryProvider.of(context).consumeWalletDeleted()) return;

      final theme = IrmaTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(
            "enrollment.wallet_deleted_toast",
            style: theme.themeData.textTheme.bodySmall!.copyWith(
              color: theme.light,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.themeData.colorScheme.secondary,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
