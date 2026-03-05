import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../../widgets/irma_quote.dart";
import "../../../widgets/session_progress_indicator.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "disclosure_make_choice_screen.dart";
import "session_scaffold.dart";

class SchemalessDisclosureOverview extends ConsumerStatefulWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;

  const SchemalessDisclosureOverview({
    super.key,
    required this.sessionState,
    required this.onDismiss,
  });

  @override
  ConsumerState<SchemalessDisclosureOverview> createState() =>
      _SchemalessDisclosureOverviewState();
}

class _SchemalessDisclosureOverviewState
    extends ConsumerState<SchemalessDisclosureOverview> {
  int get _sessionId => widget.sessionState.id;

  /// Returns the selected index for a discon, defaulting to 0.
  int _selectedIndexFor(int disconIndex) {
    final userChoices = ref
        .read(sessionUserChoicesProvider(_sessionId))
        .disclosureChoices;
    if (!userChoices.containsKey(disconIndex)) return 0;

    // Find which owned option matches the stored credential
    final stored = userChoices[disconIndex]!;
    final owned =
        widget
            .sessionState
            .disclosurePlan
            ?.disclosureChoicesOverview?[disconIndex]
            .ownedOptions ??
        [];
    for (var i = 0; i < owned.length; i++) {
      if (owned[i].hash == stored.credentialHash) return i;
    }
    return 0;
  }

  void _onApprove() {
    final repo = ref.read(irmaRepositoryProvider);
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    final userChoices = ref
        .read(sessionUserChoicesProvider(_sessionId))
        .disclosureChoices;

    final disclosureChoices = <DisclosureDisconSelection>[];
    for (var i = 0; i < choices.length; i++) {
      final stored = userChoices[i];
      if (stored != null) {
        disclosureChoices.add(DisclosureDisconSelection(credentials: [stored]));
      } else {
        // Default to first owned option
        final owned = choices[i].ownedOptions;
        if (owned != null && owned.isNotEmpty) {
          final selected = owned[0];
          disclosureChoices.add(
            DisclosureDisconSelection(
              credentials: [
                SelectedCredential(
                  credentialId: selected.credentialId,
                  credentialHash: selected.hash,
                  attributePaths: selected.attributes
                      .map((attr) => <dynamic>[attr.id])
                      .toList(),
                ),
              ],
            ),
          );
        } else {
          disclosureChoices.add(DisclosureDisconSelection(credentials: []));
        }
      }
    }

    repo.bridgedDispatch(
      SessionUserInteractionEvent.permission(
        sessionId: _sessionId,
        granted: true,
        disclosureChoices: disclosureChoices,
      ),
    );
  }

  Future<void> _showConfirmDialog() async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final isSignature = widget.sessionState.type == SessionType.signature;
    final requestorName = widget.sessionState.requestor.name.translate(lang);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => IrmaConfirmationDialog(
            titleTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.title_signature"
                : "disclosure_permission.confirm_dialog.title",
            contentTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.explanation_signature"
                : "disclosure_permission.confirm_dialog.explanation",
            contentTranslationParams: {"requestorName": requestorName},
            confirmTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.confirm_signature"
                : "disclosure_permission.confirm_dialog.confirm",
            cancelTranslationKey: isSignature
                ? "disclosure_permission.confirm_dialog.decline_signature"
                : "disclosure_permission.confirm_dialog.decline",
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      _onApprove();
    }
  }

  Future<void> _showCloseDialog() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => const IrmaConfirmationDialog(
            titleTranslationKey:
                "disclosure_permission.confirm_close_dialog.title",
            contentTranslationKey:
                "disclosure_permission.confirm_close_dialog.explanation",
            confirmTranslationKey:
                "disclosure_permission.confirm_close_dialog.confirm",
            cancelTranslationKey:
                "disclosure_permission.confirm_close_dialog.decline",
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      widget.onDismiss();
    }
  }

  void _onChangeChoice(int disconIndex) {
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    if (disconIndex >= choices.length) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DisclosureMakeChoiceScreen(
          pickOne: choices[disconIndex],
          initialSelectedIndex: _selectedIndexFor(disconIndex),
          onChoiceMade: (newIndex) {
            final owned = choices[disconIndex].ownedOptions;
            if (owned != null && newIndex < owned.length) {
              final selected = owned[newIndex];
              ref
                  .read(sessionUserChoicesProvider(_sessionId).notifier)
                  .setChoice(
                    disconIndex,
                    SelectedCredential(
                      credentialId: selected.credentialId,
                      credentialHash: selected.hash,
                      attributePaths: selected.attributes
                          .map((attr) => <dynamic>[attr.id])
                          .toList(),
                    ),
                  );
            }
          },
        ),
      ),
    );
  }

  /// Whether a discon has multiple total options (owned + obtainable).
  bool _hasMultipleOptions(DisclosurePickOne pickOne) {
    final ownedCount = pickOne.ownedOptions?.length ?? 0;
    final obtainableCount = pickOne.obtainableOptions?.length ?? 0;
    return ownedCount + obtainableCount > 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final session = widget.sessionState;
    final choices = session.disclosurePlan?.disclosureChoicesOverview ?? [];
    final isSignature = session.type == SessionType.signature;
    final requestorName = session.requestor.name.translate(lang);

    // Watch the provider so we rebuild when choices change
    ref.watch(sessionUserChoicesProvider(_sessionId));

    final requiredChoices = choices.indexed
        .where((e) => !e.$2.optional)
        .toList();
    final optionalChoices = choices.indexed
        .where((e) => e.$2.optional)
        .toList();

    return SessionScaffold(
      appBarTitle: "disclosure_permission.overview.title",
      onDismiss: _showCloseDialog,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestorSection(requestor: session.requestor),

              SessionProgressIndicator(
                contentTranslationKey:
                    "disclosure_permission.overview.explanation",
                contentTranslationParams: {"requestorName": requestorName},
              ),

              if (isSignature && session.messageToSign != null) ...[
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "disclosure_permission.overview.sign",
                  style: theme.themeData.textTheme.headlineMedium,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: theme.smallSpacing,
                    bottom: theme.defaultSpacing,
                  ),
                  child: IrmaQuote(
                    key: const Key("signature_message"),
                    quote: session.messageToSign!,
                  ),
                ),
              ],

              // Required choices
              for (final (index, pickOne) in requiredChoices)
                _DisclosureChoiceEntry(
                  pickOne: pickOne,
                  selectedIndex: _selectedIndexFor(index),
                  changeable: _hasMultipleOptions(pickOne),
                  onChangeChoice: () => _onChangeChoice(index),
                ),

              // Optional choices
              if (optionalChoices.isNotEmpty) ...[
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "disclosure_permission.optional_data",
                  style: theme.themeData.textTheme.headlineMedium,
                ),
                SizedBox(height: theme.smallSpacing),
                for (final (index, pickOne) in optionalChoices)
                  _DisclosureChoiceEntry(
                    pickOne: pickOne,
                    selectedIndex: _selectedIndexFor(index),
                    changeable: _hasMultipleOptions(pickOne),
                    onChangeChoice: () => _onChangeChoice(index),
                  ),
              ],

              if (choices.isEmpty)
                TranslatedText(
                  "disclosure_permission.no_data_selected",
                  style: theme.themeData.textTheme.headlineMedium,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: isSignature
            ? "disclosure_permission.overview.confirm_sign"
            : "disclosure_permission.overview.confirm",
        onPrimaryPressed: _showConfirmDialog,
      ),
    );
  }
}

class _RequestorSection extends StatelessWidget {
  final TrustedParty requestor;

  const _RequestorSection({required this.requestor});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final name = getTranslation(context, requestor.name);

    return IrmaCard(
      hasShadow: false,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.only(bottom: theme.defaultSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: theme.tinySpacing),
            child: IrmaAvatar(
              size: 48,
              logoPath: requestor.imagePath,
              logoSemanticsLabel: name,
              initials: name.isNotEmpty ? name[0] : null,
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Flexible(
            child: Text(name, style: theme.themeData.textTheme.headlineMedium),
          ),
        ],
      ),
    );
  }
}

/// Shows the currently selected credential for a disclosure choice, with an
/// optional "change choice" button that opens the [DisclosureMakeChoiceScreen].
class _DisclosureChoiceEntry extends StatelessWidget {
  final DisclosurePickOne pickOne;
  final int selectedIndex;
  final bool changeable;
  final VoidCallback onChangeChoice;

  const _DisclosureChoiceEntry({
    required this.pickOne,
    required this.selectedIndex,
    required this.changeable,
    required this.onChangeChoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = pickOne.ownedOptions;

    if (owned != null && owned.isNotEmpty) {
      final selected = owned[selectedIndex];

      return Padding(
        padding: EdgeInsets.only(bottom: theme.smallSpacing),
        child: Column(
          children: [
            if (changeable)
              Padding(
                padding: EdgeInsets.only(
                  bottom: theme.smallSpacing,
                  top: theme.smallSpacing,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: YiviThemedButton(
                        label: "disclosure_permission.change_choice",
                        style: YiviButtonStyle.outlined,
                        size: YiviButtonSize.small,
                        isTransparent: true,
                        onPressed: onChangeChoice,
                      ),
                    ),
                  ],
                ),
              ),
            _SelectedCredentialCard(credential: selected),
          ],
        ),
      );
    }

    // No owned options — show obtainable/missing state
    final obtainable = pickOne.obtainableOptions;
    if (obtainable != null && obtainable.isNotEmpty) {
      return Card(
        margin: EdgeInsets.only(bottom: theme.smallSpacing),
        child: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(context, "disclosure.missing_credential"),
                style: theme.themeData.textTheme.titleMedium?.copyWith(
                  color: theme.error,
                ),
              ),
              SizedBox(height: theme.smallSpacing),
              for (final cred in obtainable)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
                  child: Text(
                    getTranslation(context, cred.name),
                    style: theme.themeData.textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SelectedCredentialCard extends StatelessWidget {
  final SelectableCredentialInstance credential;

  const _SelectedCredentialCard({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (credential.imagePath.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: theme.smallSpacing),
                  child: Image.file(
                    File(credential.imagePath),
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 40, height: 40),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslation(context, credential.name),
                      style: theme.themeData.textTheme.titleSmall,
                    ),
                    Text(
                      getTranslation(context, credential.issuer.name),
                      style: theme.themeData.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (credential.attributes.isNotEmpty) ...[
            SizedBox(height: theme.smallSpacing),
            YiviCredentialCardAttributeList(credential.attributes),
          ],
        ],
      ),
    );
  }
}
