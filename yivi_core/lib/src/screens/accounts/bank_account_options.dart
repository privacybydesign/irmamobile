import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/bank_account.dart";
import "../../providers/bank_accounts_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_confirmation_dialog.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/yivi_bottom_sheet.dart";
import "bank_formatting.dart";

void _showMessage(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Lets the user connect [bank] in the browser, telling them when that did
/// not work. Completes with whether a bank was connected.
Future<bool> connectBank(
  BuildContext context,
  WidgetRef ref, {
  String? bank,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = FlutterI18n.translate(context, "accounts.connect_failed");
  try {
    return await ref.read(bankConnectorProvider).connect(bank: bank);
  } on Object catch (e) {
    debugPrint("connecting a bank failed: $e");
    _showMessage(messenger, failed);
    return false;
  }
}

/// Asks the bank of [connection] for fresh data, for all its accounts.
Future<void> refreshBankConnection(
  BuildContext context,
  WidgetRef ref,
  BankConnection connection,
) async {
  final messenger = ScaffoldMessenger.of(context);
  String t(String key) => FlutterI18n.translate(
    context,
    key,
    translationParams: {"bank": connection.bankDisplayName},
  );
  final limited = t("accounts.refresh.limit");
  final failed = t("accounts.refresh.failed");
  try {
    await ref.read(bankConnectorProvider).refresh(connection);
  } on BankAccountsRateLimitError {
    _showMessage(messenger, limited);
  } on Object catch (e) {
    debugPrint("refreshing a bank connection failed: $e");
    _showMessage(messenger, failed);
  }
}

/// Asks the user to confirm and then removes [account]. Completes with
/// whether the account was removed.
Future<bool> removeBankAccount(
  BuildContext context,
  WidgetRef ref,
  BankConnection connection,
  BankAccount account,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final connector = ref.read(bankConnectorProvider);
  final failed = FlutterI18n.translate(context, "accounts.remove.failed");
  final isLast = BankConnector.isLastAccount(connection, account);

  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (context) => IrmaConfirmationDialog(
          titleTranslationKey: "accounts.remove.title",
          contentTranslationKey: isLast
              ? "accounts.remove.explanation_last"
              : "accounts.remove.explanation",
          contentTranslationParams: {"bank": connection.bankDisplayName},
          confirmTranslationKey: "ui.delete",
          nudgeCancel: true,
        ),
      ) ??
      false;
  if (!confirmed) return false;
  try {
    await connector.removeAccount(connection, account);
    return true;
  } on Object catch (e) {
    debugPrint("removing a bank account failed: $e");
    _showMessage(messenger, failed);
    return false;
  }
}

/// Ends a whole bank connection. Used for
/// connections that have no accounts to show: failed or expired ones.
Future<void> removeBankConnection(
  BuildContext context,
  WidgetRef ref,
  BankConnection connection,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final connector = ref.read(bankConnectorProvider);
  final failed = FlutterI18n.translate(context, "accounts.remove.failed");
  try {
    await connector.removeConnection(connection.consentId);
  } on Object catch (e) {
    debugPrint("removing a bank connection failed: $e");
    _showMessage(messenger, failed);
  }
}

/// Shows what the user can do with one account: refresh it, copy its number
/// or remove it. [onRemoved] is called after the account was removed.
Future<void> showBankAccountOptions(
  BuildContext context,
  WidgetRef ref, {
  required BankConnection connection,
  required BankAccount account,
  VoidCallback? onRemoved,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final copied = FlutterI18n.translate(context, "accounts.options.copied");
  final bank = {"bank": connection.bankDisplayName};

  return showYiviBottomSheet(
    context: context,
    titleKey: "accounts.options.title",
    minHeightFraction: 0,
    child: Builder(
      builder: (sheetContext) {
        final theme = IrmaTheme.of(sheetContext);
        void close() => Navigator.of(sheetContext).pop();

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Option(
                key: const Key("bank_account_option_refresh"),
                icon: Icons.refresh,
                title: FlutterI18n.translate(
                  sheetContext,
                  "accounts.options.refresh",
                ),
                subtitle: FlutterI18n.translate(
                  sheetContext,
                  "accounts.options.refresh_explanation",
                  translationParams: bank,
                ),
                onTap: () {
                  close();
                  refreshBankConnection(context, ref, connection);
                },
              ),
              const IrmaDivider(),
              if (account.number.isNotEmpty) ...[
                _Option(
                  key: const Key("bank_account_option_copy"),
                  icon: Icons.copy_outlined,
                  title: FlutterI18n.translate(
                    sheetContext,
                    "accounts.options.copy",
                  ),
                  subtitle: formatAccountNumber(account.number),
                  onTap: () async {
                    close();
                    await Clipboard.setData(
                      ClipboardData(text: account.number),
                    );
                    _showMessage(messenger, copied);
                  },
                ),
                const IrmaDivider(),
              ],
              _Option(
                key: const Key("bank_account_option_remove"),
                icon: Icons.delete_outline,
                color: theme.error,
                title: FlutterI18n.translate(
                  sheetContext,
                  "accounts.options.remove",
                ),
                subtitle: FlutterI18n.translate(
                  sheetContext,
                  BankConnector.isLastAccount(connection, account)
                      ? "accounts.options.remove_explanation_last"
                      : "accounts.options.remove_explanation",
                  translationParams: bank,
                ),
                onTap: () async {
                  close();
                  final removed = await removeBankAccount(
                    context,
                    ref,
                    connection,
                    account,
                  );
                  if (removed) onRemoved?.call();
                },
              ),
              SizedBox(height: theme.smallSpacing),
            ],
          ),
        );
      },
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.defaultSpacing,
            vertical: theme.defaultSpacing - theme.tinySpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? theme.neutralExtraDark),
              SizedBox(width: theme.defaultSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.themeData.textTheme.headlineMedium!.copyWith(
                        fontSize: 16,
                        color: color ?? theme.dark,
                      ),
                    ),
                    SizedBox(height: theme.tinySpacing / 2),
                    Text(
                      subtitle,
                      style: theme.themeData.textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: theme.neutralExtraDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
