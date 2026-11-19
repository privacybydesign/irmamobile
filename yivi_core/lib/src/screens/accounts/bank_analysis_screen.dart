import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/bank_analysis.dart";
import "../../providers/bank_accounts_provider.dart";
import "../../providers/bank_analysis_provider.dart";
import "../../theme/theme.dart";
import "../../util/handle_pointer.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/translated_text.dart";
import "bank_formatting.dart";
import "bank_logo.dart";

/// Analyses the accounts of one bank connection and adds the result to the
/// wallet: income, housing costs and so on, as averages per month. The user
/// stays in the app from start to finish.
class BankAnalysisScreen extends ConsumerWidget {
  const BankAnalysisScreen({super.key, required this.consentId});

  final String consentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final state = ref.watch(bankAnalysisProvider(consentId));
    final notifier = ref.read(bankAnalysisProvider(consentId).notifier);

    Future<void> add() async {
      final messenger = ScaffoldMessenger.of(context);
      final failed = FlutterI18n.translate(
        context,
        "accounts.analysis.add_failed",
      );
      final pointer = await notifier.issue();
      if (!context.mounted) return;
      if (pointer == null) {
        messenger.showSnackBar(SnackBar(content: Text(failed)));
        return;
      }
      // the wallet's own screen for adding data takes over from here
      await handlePointer(context, pointer, pushReplacement: true);
    }

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: "accounts.analysis.title"),
      body: SafeArea(
        child: switch (state.stage) {
          .intro => _Intro(consentId: consentId),
          .analysing => const _Analysing(),
          .review => _Review(state: state, onToggle: notifier.toggle),
          .failed => _Failed(error: state.error),
        },
      ),
      bottomNavigationBar: switch (state.stage) {
        .intro => IrmaBottomBar(
          key: const Key("bank_analysis_start"),
          primaryButtonLabel: "accounts.analysis.intro.start",
          onPrimaryPressed: notifier.start,
        ),
        .review => IrmaBottomBar(
          key: const Key("bank_analysis_add"),
          primaryButtonLabel: "accounts.analysis.review.add",
          onPrimaryPressed: state.selected.isEmpty || state.issuing
              ? null
              : add,
        ),
        .failed => IrmaBottomBar(
          key: const Key("bank_analysis_retry"),
          primaryButtonLabel: "ui.retry",
          onPrimaryPressed: notifier.start,
        ),
        .analysing => null,
      },
    );
  }
}

class _Intro extends ConsumerWidget {
  const _Intro({required this.consentId});

  final String consentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final connection = ref
        .watch(bankConnectionsProvider)
        .value
        ?.firstWhereOrNull((c) => c.consentId == consentId);
    final bank = {"bank": connection?.bankDisplayName ?? ""};

    return ListView(
      padding: EdgeInsets.all(theme.defaultSpacing),
      children: [
        SizedBox(height: theme.defaultSpacing),
        if (connection != null)
          Center(child: BankLogo.of(connection, size: 72)),
        SizedBox(height: theme.mediumSpacing),
        TranslatedText(
          "accounts.analysis.intro.header",
          style: theme.themeData.textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.smallSpacing),
        TranslatedText(
          "accounts.analysis.intro.explanation",
          textAlign: TextAlign.center,
          style: theme.themeData.textTheme.bodyMedium!.copyWith(
            color: theme.neutralExtraDark,
          ),
        ),
        SizedBox(height: theme.mediumSpacing),
        IrmaCard(
          child: Column(
            children: [
              _Step(
                icon: Icons.receipt_long_outlined,
                textKey: "accounts.analysis.intro.step_transactions",
                params: bank,
              ),
              SizedBox(height: theme.defaultSpacing),
              const _Step(
                icon: Icons.donut_small_outlined,
                textKey: "accounts.analysis.intro.step_averages",
              ),
              SizedBox(height: theme.defaultSpacing),
              const _Step(
                icon: Icons.checklist_outlined,
                textKey: "accounts.analysis.intro.step_choose",
              ),
            ],
          ),
        ),
        SizedBox(height: theme.mediumSpacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: theme.neutralDark),
            SizedBox(width: theme.smallSpacing),
            Expanded(
              child: TranslatedText(
                "accounts.analysis.intro.privacy_note",
                style: theme.themeData.textTheme.bodySmall!.copyWith(
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.textKey, this.params});

  final IconData icon;
  final String textKey;
  final Map<String, String>? params;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.backgroundTertiary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.secondary),
        ),
        SizedBox(width: theme.defaultSpacing),
        Expanded(
          child: TranslatedText(
            textKey,
            translationParams: params,
            style: theme.themeData.textTheme.bodyMedium!.copyWith(
              fontSize: 15,
              color: theme.dark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Analysing extends StatelessWidget {
  const _Analysing();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          key: const Key("bank_analysis_progress"),
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: theme.mediumSpacing),
            TranslatedText(
              "accounts.analysis.progress.header",
              style: theme.themeData.textTheme.displayMedium!.copyWith(
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.smallSpacing),
            const TranslatedText(
              "accounts.analysis.progress.explanation",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.error});

  final BankAnalysisFailure? error;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.error),
            SizedBox(height: theme.defaultSpacing),
            TranslatedText(switch (error) {
              .noTransactions => "accounts.analysis.failed.no_transactions",
              .rateLimit => "accounts.analysis.failed.rate_limit",
              .timeout => "accounts.analysis.failed.timeout",
              _ => "accounts.analysis.failed.other",
            }, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.state, required this.onToggle});

  final BankAnalysisState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    // every card about amounts covers the same period
    final period = state.groups
        .expand((g) => g.credentials)
        .map((c) => c.attributes)
        .firstWhereOrNull((a) => a.containsKey("months"));

    return ListView(
      key: const Key("bank_analysis_review"),
      padding: EdgeInsets.all(theme.defaultSpacing),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.tinySpacing,
            theme.smallSpacing,
            theme.tinySpacing,
            theme.defaultSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                "accounts.analysis.review.explanation",
                style: theme.themeData.textTheme.bodyMedium!.copyWith(
                  color: theme.neutralExtraDark,
                ),
              ),
              if (period != null) ...[
                SizedBox(height: theme.smallSpacing),
                TranslatedText(
                  "accounts.analysis.review.period",
                  translationParams: {
                    "months": period["months"] ?? "",
                    "start": _date(context, period["periodstart"]),
                    "end": _date(context, period["periodend"]),
                  },
                  style: theme.themeData.textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.neutralDark,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final group in state.groups)
          Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: _GroupCard(
              group: group,
              selected: state.selected.contains(group.key),
              onToggle: () => onToggle(group.key),
            ),
          ),
        SizedBox(height: theme.defaultSpacing),
      ],
    );
  }

  static String _date(BuildContext context, String? value) {
    final date = DateTime.tryParse(value ?? "");
    return date == null ? value ?? "" : formatBankDate(context, date);
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  final AnalysisCredentialGroup group;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    final muted = theme.themeData.textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      color: theme.neutralExtraDark,
    );
    final value = theme.themeData.textTheme.bodyMedium!.copyWith(
      fontSize: 15,
      color: theme.dark,
    );

    final rows = <Widget>[
      for (final credential in group.credentials)
        if (group.hasAmounts)
          for (final (attribute, amount) in group.amountsOf(credential))
            Row(
              children: [
                Expanded(
                  child: Text(attribute.name.translate(lang), style: value),
                ),
                SizedBox(width: theme.smallSpacing),
                Text(
                  FlutterI18n.translate(
                    context,
                    "accounts.analysis.review.per_month",
                    translationParams: {
                      "amount": formatWholeEuros(context, amount),
                    },
                  ),
                  style: value.copyWith(
                    fontWeight: FontWeight.w600,
                    color: amount > 0 ? theme.success : theme.dark,
                  ),
                ),
              ],
            )
        else
          // a bank account: its number and holder
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatAccountNumber(credential.attributes["iban"] ?? ""),
                style: value,
              ),
              if ((credential.attributes["accountholder"] ?? "").isNotEmpty)
                Text(credential.attributes["accountholder"]!, style: muted),
            ],
          ),
    ];

    return IrmaCard(
      key: Key("bank_analysis_group_${group.key}"),
      margin: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: theme.borderRadius,
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.definition.name.translate(lang),
                            style: theme.themeData.textTheme.headlineMedium!
                                .copyWith(fontSize: 16, color: theme.dark),
                          ),
                          Text(
                            group.definition.description.translate(lang),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: theme.smallSpacing),
                    // the whole card toggles; the box only shows the state
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: selected,
                            onChanged: (_) {},
                            activeColor: theme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.defaultSpacing - theme.tinySpacing),
                const IrmaDivider(),
                SizedBox(height: theme.defaultSpacing - theme.tinySpacing),
                if (rows.isEmpty)
                  TranslatedText(
                    "accounts.analysis.review.nothing_found",
                    style: muted,
                  )
                else
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0) SizedBox(height: theme.smallSpacing),
                    row,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
