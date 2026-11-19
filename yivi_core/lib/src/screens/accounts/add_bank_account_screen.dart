import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../models/bank_account.dart";
import "../../providers/bank_accounts_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/chevron.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";
import "bank_account_options.dart";
import "bank_logo.dart";

/// Lets the user choose the bank to add an account of. After choosing, the
/// user logs in at that bank in the browser (or the bank's own app): that
/// part can't be done inside this app.
class AddBankAccountScreen extends ConsumerStatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  ConsumerState<AddBankAccountScreen> createState() =>
      _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends ConsumerState<AddBankAccountScreen> {
  /// The bank the user is being sent to, to keep them from choosing twice.
  String? _connecting;

  Future<void> _connect(Bank bank) async {
    if (_connecting != null) return;
    setState(() => _connecting = bank.key);
    final connected = await connectBank(context, ref, bank: bank.key);
    if (!mounted) return;
    setState(() => _connecting = null);
    if (connected) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final banks = ref.watch(banksProvider);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: "accounts.choose_bank.title"),
      body: SafeArea(
        child: banks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(theme.largeSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: theme.neutral,
                  ),
                  SizedBox(height: theme.defaultSpacing),
                  const TranslatedText(
                    "accounts.choose_bank.load_failed",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: theme.mediumSpacing),
                  YiviThemedButton(
                    label: "ui.retry",
                    style: YiviButtonStyle.outlined,
                    onPressed: () => ref.invalidate(banksProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (banks) => ListView(
            key: const Key("bank_list"),
            padding: EdgeInsets.all(theme.defaultSpacing),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.tinySpacing,
                  theme.smallSpacing,
                  theme.tinySpacing,
                  theme.defaultSpacing,
                ),
                child: TranslatedText(
                  "accounts.choose_bank.explanation",
                  style: theme.themeData.textTheme.bodyMedium!.copyWith(
                    color: theme.neutralExtraDark,
                  ),
                ),
              ),
              IrmaCard(
                // IrmaCard calls the space around its child the margin
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, bank) in banks.indexed) ...[
                      if (i > 0)
                        IrmaDivider(
                          padding: EdgeInsets.only(
                            left: theme.defaultSpacing * 2 + 44,
                          ),
                        ),
                      _BankTile(
                        bank: bank,
                        connecting: _connecting == bank.key,
                        enabled: _connecting == null,
                        onTap: () => _connect(bank),
                      ),
                    ],
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
                      "accounts.choose_bank.provider_note",
                      style: theme.themeData.textTheme.bodySmall!.copyWith(
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: theme.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.bank,
    required this.connecting,
    required this.enabled,
    required this.onTap,
  });

  final Bank bank;
  final bool connecting;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key("bank_${bank.key}"),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.defaultSpacing,
              vertical: theme.defaultSpacing - theme.tinySpacing,
            ),
            child: Row(
              children: [
                BankLogo(name: bank.name, logoUrl: bank.logoUrl, size: 44),
                SizedBox(width: theme.defaultSpacing),
                Expanded(
                  child: Text(
                    bank.name,
                    style: theme.themeData.textTheme.headlineMedium!.copyWith(
                      fontSize: 16,
                      color: theme.dark,
                    ),
                  ),
                ),
                SizedBox(width: theme.smallSpacing),
                if (connecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
