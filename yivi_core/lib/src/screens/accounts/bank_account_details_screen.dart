import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../models/bank_account.dart";
import "../../providers/bank_accounts_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/irma_icon_button.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";
import "bank_account_options.dart";
import "bank_accounts_list.dart";
import "bank_formatting.dart";
import "bank_logo.dart";

/// One bank account: its balance and the transactions of the last 90 days.
class BankAccountDetailsScreen extends ConsumerWidget {
  const BankAccountDetailsScreen({
    super.key,
    required this.consentId,
    required this.accountId,
  });

  final String consentId;
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    // read from the list, so the balance follows a refresh
    final connections = ref.watch(bankConnectionsProvider).value;
    final connection = connections?.firstWhereOrNull(
      (c) => c.consentId == consentId,
    );
    final account = connection?.accounts.firstWhereOrNull(
      (a) => a.id == accountId,
    );

    final query = BankTransactionsQuery(
      consentId: consentId,
      accountId: accountId,
    );
    // fetch the transactions again when the bank data was updated
    ref.listen(
      bankConnectionsProvider.select(
        (value) => value.value
            ?.firstWhereOrNull((c) => c.consentId == consentId)
            ?.updatedAt,
      ),
      (previous, next) {
        if (previous != null && next != previous) {
          ref.invalidate(bankTransactionsProvider(query));
        }
      },
    );

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "accounts.details.title",
        actions: [
          if (connection != null && account != null)
            IrmaIconButton(
              key: const Key("bank_account_options_button"),
              icon: Icons.more_horiz,
              size: 28,
              semanticsLabelKey: "accounts.options.title",
              onTap: () => showBankAccountOptions(
                context,
                ref,
                connection: connection,
                account: account,
                onRemoved: () {
                  if (context.mounted) context.pop();
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: connection == null || account == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bankConnectionsProvider);
                  ref.invalidate(bankTransactionsProvider(query));
                  await ref.read(bankTransactionsProvider(query).future);
                },
                child: ListView(
                  key: const Key("bank_account_details"),
                  padding: EdgeInsets.all(theme.defaultSpacing),
                  children: [
                    _AccountSummary(connection: connection, account: account),
                    SizedBox(height: theme.mediumSpacing),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.tinySpacing,
                      ),
                      child: TranslatedText(
                        "accounts.details.transactions",
                        style: theme.themeData.textTheme.headlineMedium!
                            .copyWith(fontSize: 18, color: theme.dark),
                      ),
                    ),
                    SizedBox(height: theme.smallSpacing),
                    _Transactions(query: query),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.connection, required this.account});

  final BankConnection connection;
  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final balance = account.balance;
    final expiresAt = connection.expiresAt;
    final caption = theme.themeData.textTheme.bodySmall!.copyWith(
      fontSize: 13,
      height: 1.45,
      color: theme.neutralDark,
    );

    // IrmaCard pads its child by default
    return IrmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BankLogo.of(connection),
              SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.holder.isNotEmpty
                          ? account.holder
                          : connection.bankDisplayName,
                      style: theme.themeData.textTheme.headlineMedium!.copyWith(
                        fontSize: 16,
                        color: theme.dark,
                      ),
                    ),
                    if (account.holder.isNotEmpty)
                      Text(
                        connection.bankDisplayName,
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
          SizedBox(height: theme.defaultSpacing),
          Text(
            formatAccountNumber(account.number),
            key: const Key("bank_account_number"),
            style: theme.themeData.textTheme.bodyMedium!.copyWith(
              color: theme.dark,
              letterSpacing: 0.5,
            ),
          ),
          if (balance != null) ...[
            SizedBox(height: theme.defaultSpacing),
            const IrmaDivider(),
            SizedBox(height: theme.defaultSpacing),
            TranslatedText("accounts.details.balance", style: caption),
            Text(
              formatBankAmount(context, balance.amount, balance.currency),
              key: const Key("bank_account_balance"),
              style: theme.themeData.textTheme.displayLarge!.copyWith(
                fontSize: 32,
                height: 1.25,
                color: balance.amount < 0 ? theme.error : theme.dark,
              ),
            ),
          ],
          SizedBox(height: theme.smallSpacing),
          BankUpdatedLabel(connection: connection),
          if (expiresAt != null)
            TranslatedText(
              "accounts.details.valid_until",
              translationParams: {"date": formatBankDate(context, expiresAt)},
              style: caption,
            ),
        ],
      ),
    );
  }
}

class _Transactions extends ConsumerWidget {
  const _Transactions({required this.query});

  final BankTransactionsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final transactions = ref.watch(bankTransactionsProvider(query));

    return transactions.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => IrmaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TranslatedText(
              "accounts.details.load_failed",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.defaultSpacing),
            YiviThemedButton(
              label: "ui.retry",
              style: YiviButtonStyle.outlined,
              size: YiviButtonSize.small,
              onPressed: () => ref.invalidate(bankTransactionsProvider(query)),
            ),
          ],
        ),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return IrmaCard(
            child: const TranslatedText(
              "accounts.details.no_transactions",
              textAlign: TextAlign.center,
            ),
          );
        }
        // newest first, one card per day
        final days = groupBy(
          transactions,
          (BankTransaction tx) => tx.date == null
              ? null
              : DateTime(tx.date!.year, tx.date!.month, tx.date!.day),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final MapEntry(key: day, value: ofDay) in days.entries) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.tinySpacing,
                  theme.smallSpacing,
                  theme.tinySpacing,
                  theme.smallSpacing,
                ),
                child: Text(
                  day == null
                      ? FlutterI18n.translate(context, "ui.unknown")
                      : formatBankDay(context, day),
                  style: theme.themeData.textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.neutralExtraDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IrmaCard(
                // IrmaCard calls the space around its child the margin
                margin: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                child: Column(
                  children: [
                    for (final (i, tx) in ofDay.indexed) ...[
                      if (i > 0) const IrmaDivider(),
                      _TransactionRow(transaction: tx),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final BankTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final incoming = transaction.amount > 0;
    final showDescription =
        transaction.description.isNotEmpty &&
        transaction.description != transaction.title;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.defaultSpacing - theme.tinySpacing,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: incoming ? theme.successSurface : theme.backgroundTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              incoming ? Icons.south_west : Icons.north_east,
              size: 18,
              color: incoming ? theme.success : theme.neutralExtraDark,
            ),
          ),
          SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isEmpty
                      ? FlutterI18n.translate(context, "ui.unknown")
                      : transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.themeData.textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.dark,
                  ),
                ),
                if (showDescription)
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.themeData.textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.neutralExtraDark,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Text(
            formatBankAmount(
              context,
              transaction.amount,
              transaction.currency,
              explicitPlus: true,
            ),
            style: theme.themeData.textTheme.bodyMedium!.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: incoming ? theme.success : theme.dark,
            ),
          ),
        ],
      ),
    );
  }
}
