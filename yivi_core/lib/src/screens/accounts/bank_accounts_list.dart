import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/bank_account.dart";
import "../../providers/bank_accounts_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/chevron.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_bottom_sheet.dart";
import "../../widgets/yivi_themed_button.dart";
import "bank_account_options.dart";
import "bank_formatting.dart";
import "bank_logo.dart";

/// The accounts section of the data tab: every bank account the user added,
/// one card per account.
class BankAccountsList extends ConsumerWidget {
  const BankAccountsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final connections = ref.watch(bankConnectionsProvider);

    return connections.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _LoadFailed(onRetry: () => ref.invalidate(bankConnectionsProvider)),
      data: (connections) {
        if (connections.isEmpty) return const _NoAccountsYet();

        final spacing = SizedBox(height: theme.smallSpacing);
        return RefreshIndicator(
          onRefresh: () => ref.refresh(bankConnectionsProvider.future),
          child: ListView(
            key: const Key("bank_accounts_list"),
            padding: EdgeInsets.all(theme.defaultSpacing),
            children: [
              _TotalBalance(connections: connections),
              for (final connection in connections)
                if (connection.status != BankConnectionStatus.ready ||
                    connection.accounts.isEmpty) ...[
                  _ConnectionStatusCard(connection: connection),
                  spacing,
                ] else
                  for (final account in connection.accounts) ...[
                    _AccountCard(connection: connection, account: account),
                    spacing,
                  ],
              _AnalyseAccounts(connections: connections),
              spacing,
              YiviThemedButton(
                key: const Key("bank_accounts_connect"),
                label: "accounts.add",
                style: YiviButtonStyle.outlined,
                onPressed: context.pushAddBankAccountScreen,
              ),
              SizedBox(height: theme.mediumSpacing),
              const _PrivacyNote(),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}

/// Offers to analyse the accounts and add the result to the wallet. The
/// analysis is per bank, so with several banks the user chooses one.
class _AnalyseAccounts extends StatelessWidget {
  const _AnalyseAccounts({required this.connections});

  final List<BankConnection> connections;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final ready = [
      for (final c in connections)
        if (c.status == BankConnectionStatus.ready && c.accounts.isNotEmpty) c,
    ];
    if (ready.isEmpty) return const SizedBox.shrink();

    void analyse(BankConnection connection) =>
        context.pushBankAnalysisScreen(consentId: connection.consentId);

    return IrmaCard(
      key: const Key("bank_accounts_analyse"),
      style: IrmaCardStyle.highlighted,
      margin: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: theme.borderRadius,
          onTap: () => ready.length == 1
              ? analyse(ready.single)
              : showYiviBottomSheet(
                  context: context,
                  titleKey: "accounts.analysis.choose_bank",
                  minHeightFraction: 0,
                  child: Builder(
                    builder: (sheetContext) => SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final connection in ready)
                            ListTile(
                              key: Key(
                                "bank_analysis_bank_${connection.consentId}",
                              ),
                              leading: BankLogo.of(connection, size: 40),
                              title: Text(
                                connection.bankDisplayName,
                                style: theme.themeData.textTheme.headlineMedium!
                                    .copyWith(fontSize: 16, color: theme.dark),
                              ),
                              subtitle: Text(
                                connection.accounts
                                    .map((a) => formatAccountNumber(a.number))
                                    .join("\n"),
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                analyse(connection);
                              },
                            ),
                          SizedBox(height: theme.smallSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
          child: Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Row(
              children: [
                Icon(Icons.insights_outlined, size: 28, color: theme.secondary),
                SizedBox(width: theme.defaultSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        "accounts.analysis.entry.title",
                        style: theme.themeData.textTheme.headlineMedium!
                            .copyWith(fontSize: 16, color: theme.dark),
                      ),
                      TranslatedText(
                        "accounts.analysis.entry.subtitle",
                        style: theme.themeData.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: theme.neutralExtraDark,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.smallSpacing),
                const Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: theme.neutral),
            SizedBox(height: theme.defaultSpacing),
            const TranslatedText(
              "accounts.load_failed",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.mediumSpacing),
            YiviThemedButton(
              key: const Key("bank_accounts_retry"),
              label: "ui.retry",
              style: YiviButtonStyle.outlined,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 18, color: theme.neutralDark),
        SizedBox(width: theme.smallSpacing),
        Expanded(
          child: TranslatedText(
            "accounts.privacy_note",
            style: theme.themeData.textTheme.bodySmall!.copyWith(
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoAccountsYet extends ConsumerWidget {
  const _NoAccountsYet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: theme.largeSpacing),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.light,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                size: 44,
                color: theme.secondary,
              ),
            ),
          ),
          SizedBox(height: theme.mediumSpacing),
          TranslatedText(
            "accounts.empty.title",
            style: theme.themeData.textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: theme.smallSpacing),
          const TranslatedText(
            "accounts.empty.subtitle",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: theme.largeSpacing),
          YiviThemedButton(
            key: const Key("bank_accounts_connect"),
            label: "accounts.add",
            onPressed: context.pushAddBankAccountScreen,
          ),
          SizedBox(height: theme.mediumSpacing),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}

/// The sum of all balances, shown when there is more than one account and
/// they are all in the same currency.
class _TotalBalance extends StatelessWidget {
  const _TotalBalance({required this.connections});

  final List<BankConnection> connections;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final accounts = [
      for (final c in connections)
        if (c.status == BankConnectionStatus.ready) ...c.accounts,
    ];
    final balances = [for (final a in accounts) ?a.balance];
    final currencies = {for (final b in balances) b.currency};
    if (accounts.length < 2 ||
        balances.length != accounts.length ||
        currencies.length != 1) {
      return const SizedBox.shrink();
    }
    final total = balances.fold(0.0, (sum, b) => sum + b.amount);

    return Padding(
      padding: EdgeInsets.only(
        left: theme.tinySpacing,
        right: theme.tinySpacing,
        top: theme.smallSpacing,
        bottom: theme.mediumSpacing,
      ),
      child: Column(
        key: const Key("bank_accounts_total"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            "accounts.total",
            translationParams: {"count": accounts.length.toString()},
            style: theme.themeData.textTheme.bodyMedium!.copyWith(
              color: theme.neutralExtraDark,
            ),
          ),
          Text(
            formatBankAmount(context, total, currencies.single),
            style: theme.themeData.textTheme.displayLarge!.copyWith(
              fontSize: 32,
              height: 1.25,
              color: theme.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.connection, required this.account});

  final BankConnection connection;
  final BankAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final balance = account.balance;
    final title = account.holder.isNotEmpty
        ? account.holder
        : connection.bankDisplayName;

    return IrmaCard(
      key: Key("bank_account_${account.id}"),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: theme.borderRadius,
          onTap: () => context.pushBankAccountDetailsScreen(
            BankAccountDetailsRouteParams(
              consentId: connection.consentId,
              accountId: account.id,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.defaultSpacing,
                  theme.defaultSpacing,
                  theme.tinySpacing,
                  theme.defaultSpacing - theme.tinySpacing,
                ),
                child: Row(
                  children: [
                    BankLogo.of(connection),
                    SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.themeData.textTheme.headlineMedium!
                                .copyWith(fontSize: 16, color: theme.dark),
                          ),
                          Text(
                            formatAccountNumber(account.number),
                            style: theme.themeData.textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 14,
                                  color: theme.neutralExtraDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key("bank_account_options_${account.id}"),
                      icon: Icon(Icons.more_horiz, color: theme.neutralDark),
                      tooltip: FlutterI18n.translate(
                        context,
                        "accounts.options.title",
                      ),
                      onPressed: () => showBankAccountOptions(
                        context,
                        ref,
                        connection: connection,
                        account: account,
                      ),
                    ),
                  ],
                ),
              ),
              IrmaDivider(
                padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.defaultSpacing,
                  theme.defaultSpacing - theme.tinySpacing,
                  theme.defaultSpacing,
                  theme.defaultSpacing,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (account.holder.isNotEmpty)
                            Text(
                              connection.bankDisplayName,
                              style: theme.themeData.textTheme.bodySmall!
                                  .copyWith(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: theme.neutralExtraDark,
                                  ),
                            ),
                          BankUpdatedLabel(connection: connection),
                        ],
                      ),
                    ),
                    if (balance != null)
                      Text(
                        formatBankAmount(
                          context,
                          balance.amount,
                          balance.currency,
                        ),
                        style: theme.themeData.textTheme.displayMedium!
                            .copyWith(
                              fontSize: 20,
                              height: 1.2,
                              color: balance.amount < 0
                                  ? theme.error
                                  : theme.dark,
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

/// When the data of a connection was last fetched from the bank, or that it
/// is being fetched right now.
class BankUpdatedLabel extends StatelessWidget {
  const BankUpdatedLabel({super.key, required this.connection});

  final BankConnection connection;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final style = theme.themeData.textTheme.bodySmall!.copyWith(
      fontSize: 13,
      height: 1.45,
      color: theme.neutralDark,
    );

    if (connection.refreshing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.neutralDark,
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          TranslatedText("accounts.refresh.busy", style: style),
        ],
      );
    }
    final updatedAt = connection.updatedAt;
    if (updatedAt == null) return const SizedBox.shrink();
    return TranslatedText(
      "accounts.updated",
      translationParams: {"moment": formatBankMoment(context, updatedAt)},
      style: style,
    );
  }
}

/// A bank connection without accounts to show: it is still being set up, it
/// failed, or it expired.
class _ConnectionStatusCard extends ConsumerWidget {
  const _ConnectionStatusCard({required this.connection});

  final BankConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final pending = connection.status == BankConnectionStatus.pending;
    final name = connection.bankDisplayName;

    return IrmaCard(
      key: Key("bank_connection_${connection.consentId}"),
      style: pending ? IrmaCardStyle.normal : IrmaCardStyle.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      name.isEmpty
                          ? FlutterI18n.translate(
                              context,
                              "accounts.unknown_bank",
                            )
                          : name,
                      style: theme.themeData.textTheme.headlineMedium!.copyWith(
                        fontSize: 16,
                        color: theme.dark,
                      ),
                    ),
                    TranslatedText(
                      switch (connection.status) {
                        .pending => "accounts.status.pending",
                        .failed => "accounts.status.failed",
                        .gone => "accounts.status.gone",
                        .ready => "accounts.status.no_accounts",
                      },
                      style: theme.themeData.textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: theme.neutralExtraDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (pending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (!pending) ...[
            SizedBox(height: theme.defaultSpacing),
            YiviThemedButton(
              key: Key("bank_connection_remove_${connection.consentId}"),
              label: "accounts.status.remove",
              style: YiviButtonStyle.outlined,
              size: YiviButtonSize.small,
              onPressed: () => removeBankConnection(context, ref, connection),
            ),
          ],
        ],
      ),
    );
  }
}
