import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_action_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/irma_quote.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/session_progress_indicator.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "disclosure_make_choice_screen.dart";
import "disclosure_selection.dart";
import "session_scaffold.dart";

class DisclosureChoicesOverview extends ConsumerStatefulWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;
  final ValueChanged<List<DisclosureDisconSelection>> onChoicesConfirmed;
  final bool hasIssueDuringDisclosure;

  const DisclosureChoicesOverview({
    super.key,
    required this.sessionState,
    required this.onDismiss,
    required this.onChoicesConfirmed,
    this.hasIssueDuringDisclosure = false,
  });

  @override
  ConsumerState<DisclosureChoicesOverview> createState() =>
      _DisclosureChoicesOverviewState();
}

class _DisclosureChoicesOverviewState
    extends ConsumerState<DisclosureChoicesOverview> {
  int get _sessionId => widget.sessionState.id;

  /// Returns the selected bundle index for a discon, defaulting to 0.
  ///
  /// Bundle identity is determined by *set equality* over credential hashes.
  /// Two distinct bundles whose credentials hash to the same set would map to
  /// the same index here — acceptable because in that case the disclosed
  /// payload is identical. Falls back to 0 (silently) when no bundle matches,
  /// e.g. after a credential was re-issued with a new hash.
  int _selectedIndexFor(int disconIndex) {
    final overview =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview;
    if (overview == null || disconIndex < 0 || disconIndex >= overview.length) {
      return 0;
    }
    final userChoices = ref
        .read(sessionUserChoicesProvider(_sessionId))
        .disclosureChoices;
    if (!userChoices.containsKey(disconIndex)) return 0;

    final storedHashes = userChoices[disconIndex]!.credentialHashes;
    final owned = overview[disconIndex].ownedOptions ?? [];
    return selectedBundleIndex(owned, storedHashes) ?? 0;
  }

  List<DisclosureDisconSelection> _buildDisclosureChoices() {
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    final userState = ref.read(sessionUserChoicesProvider(_sessionId));
    final userChoices = userState.disclosureChoices;
    final addedOptional = userState.addedOptionalIndices;

    final disclosureChoices = <DisclosureDisconSelection>[];
    for (var i = 0; i < choices.length; i++) {
      // Skip optional choices that haven't been added
      if (choices[i].optional && !addedOptional.contains(i)) {
        disclosureChoices.add(DisclosureDisconSelection(credentials: []));
        continue;
      }

      // Re-resolve the stored selection against the current owned options by
      // its credential-hash identity. This keeps the disclosed bundle in sync
      // with what the overview displays (via _selectedIndexFor) even when the
      // owned list shifted — e.g. a credential was deleted mid-session (#520).
      // Falls back to the first owned bundle when nothing is stored or the
      // stored selection no longer exists.
      final owned = choices[i].ownedOptions ?? [];
      final stored = userChoices[i];
      final bundle =
          (stored != null
              ? resolveSelectedBundle(owned, stored.credentialHashes)
              : null) ??
          owned.firstOrNull;
      if (bundle == null) {
        disclosureChoices.add(DisclosureDisconSelection(credentials: []));
        continue;
      }

      disclosureChoices.add(
        DisclosureDisconSelection(credentials: _bundleToSelected(bundle)),
      );
    }
    return disclosureChoices;
  }

  List<SelectedCredential> _bundleToSelected(DisclosureBundle bundle) {
    return bundle.credentials
        .map(
          (c) => SelectedCredential(
            credentialId: c.credentialId,
            credentialHash: c.hash,
            attributePaths: c.attributes.map((a) => a.claimPath).toList(),
          ),
        )
        .toList();
  }

  void _onApprove() {
    final disclosureChoices = _buildDisclosureChoices();
    widget.onChoicesConfirmed(disclosureChoices);
  }

  /// Returns true if any credential in the selected bundle is expired, revoked,
  /// or has zero remaining batch instances. Disclosing a bundle is atomic — if
  /// any credential is unsharable, the whole bundle is.
  bool _hasUnsharableSelection() {
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    final userState = ref.read(sessionUserChoicesProvider(_sessionId));
    final addedOptional = userState.addedOptionalIndices;

    final now = DateTime.now();
    for (var i = 0; i < choices.length; i++) {
      final pickOne = choices[i];
      // Skip optional choices that haven't been added
      if (pickOne.optional && !addedOptional.contains(i)) continue;

      final owned = pickOne.ownedOptions;
      if (owned == null || owned.isEmpty) continue;

      final selectedIndex = _selectedIndexFor(i);
      if (selectedIndex >= owned.length) continue;

      for (final instance in owned[selectedIndex].credentials) {
        if (instance.expiryDate != null) {
          final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(
            instance.expiryDate! * 1000,
          );
          if (expiryDateTime.isBefore(now)) return true;
        }

        if (instance.revoked) return true;
        if (instance.batchInstanceCountRemaining != null &&
            instance.batchInstanceCountRemaining! <= 0) {
          return true;
        }
      }
    }
    return false;
  }

  void _onChangeChoice(int disconIndex, {bool addOptional = false}) {
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    if (disconIndex >= choices.length) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DisclosureMakeChoiceScreen(
          pickOne: choices[disconIndex],
          initialSelectedIndex: _selectedIndexFor(disconIndex),
          sessionId: _sessionId,
          disconIndex: disconIndex,
          addOptional: addOptional,
          onChoiceMade: (bundle) {
            final notifier = ref.read(
              sessionUserChoicesProvider(_sessionId).notifier,
            );
            if (addOptional) {
              notifier.addOptional(disconIndex);
            }
            // The make-choice screen resolves the selected bundle by its stable
            // credential-hash identity, so we can store it directly without
            // re-indexing a (possibly shifted) owned-options list. See #520.
            notifier.setBundle(disconIndex, bundle);
          },
        ),
      ),
    );
  }

  void _onRemoveOptional(int disconIndex) {
    ref
        .read(sessionUserChoicesProvider(_sessionId).notifier)
        .removeOptional(disconIndex);
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

    final confirmButtonKey = switch (session.type) {
      .issuance => "ui.next",
      .disclosure => "disclosure_permission.overview.confirm",
      .signature => "disclosure_permission.overview.confirm_sign",
    };

    // Watch the provider so we rebuild when choices change
    final userState = ref.watch(sessionUserChoicesProvider(_sessionId));
    final addedOptional = userState.addedOptionalIndices;

    final requiredChoices = choices.indexed
        .where((e) => !e.$2.optional)
        .toList();
    final allOptionalChoices = choices.indexed
        .where((e) => e.$2.optional)
        .toList();
    final addedOptionalChoices = allOptionalChoices
        .where((e) => addedOptional.contains(e.$1))
        .toList();
    final hasUnaddedOptional =
        addedOptionalChoices.length < allOptionalChoices.length;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.overview.title",
      onDismiss: widget.onDismiss,
      body: SingleChildScrollView(
        padding: .all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              RequestorHeader(
                requestor: session.requestor,
                isVerified: session.requestor.verified,
              ),

              if (widget.hasIssueDuringDisclosure)
                SessionProgressIndicator(
                  step: 2,
                  stepCount: 2,
                  contentTranslationKey:
                      "disclosure_permission.overview.explanation",
                  contentTranslationParams: {"requestorName": requestorName},
                )
              else
                SizedBox(height: theme.defaultSpacing),

              if (isSignature && session.messageToSign != null) ...[
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "disclosure_permission.overview.sign",
                  style: theme.themeData.textTheme.headlineMedium,
                ),
                Padding(
                  padding: .only(
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

              // Added optional choices
              if (addedOptionalChoices.isNotEmpty) ...[
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "disclosure_permission.optional_data",
                  style: theme.themeData.textTheme.headlineMedium,
                ),
                SizedBox(height: theme.smallSpacing),
                for (final (index, pickOne) in addedOptionalChoices)
                  _DisclosureChoiceEntry(
                    pickOne: pickOne,
                    selectedIndex: _selectedIndexFor(index),
                    changeable: _hasMultipleOptions(pickOne),
                    optional: true,
                    onChangeChoice: () => _onChangeChoice(index),
                    onRemove: () => _onRemoveOptional(index),
                  ),
              ],

              if (choices.isEmpty ||
                  (requiredChoices.isEmpty && addedOptionalChoices.isEmpty))
                TranslatedText(
                  "disclosure_permission.no_data_selected",
                  style: theme.themeData.textTheme.headlineMedium,
                ),

              // Add optional data button
              if (hasUnaddedOptional) ...[
                SizedBox(height: theme.defaultSpacing),
                IrmaActionCard(
                  titleKey: "disclosure_permission.add_optional_data",
                  icon: Icons.add_circle,
                  isFancy: false,
                  onTap: () {
                    // Find the first unadded optional choice
                    final firstUnadded = allOptionalChoices.firstWhere(
                      (e) => !addedOptional.contains(e.$1),
                    );
                    _onChangeChoice(firstUnadded.$1, addOptional: true);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: confirmButtonKey,
        onPrimaryPressed: _hasUnsharableSelection() ? null : _onApprove,
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
  final bool optional;
  final VoidCallback onChangeChoice;
  final VoidCallback? onRemove;

  const _DisclosureChoiceEntry({
    required this.pickOne,
    required this.selectedIndex,
    required this.changeable,
    this.optional = false,
    required this.onChangeChoice,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = pickOne.ownedOptions;

    if (owned != null && owned.isNotEmpty) {
      final bundle = owned[selectedIndex];
      final credentials = bundle.credentials;

      return Padding(
        padding: .only(bottom: theme.defaultSpacing),
        child: Column(
          children: [
            if (changeable && !optional)
              Padding(
                padding: .only(
                  bottom: theme.smallSpacing,
                  top: theme.smallSpacing,
                ),
                child: Row(
                  mainAxisAlignment: .end,
                  children: [
                    Flexible(
                      child: YiviThemedButton(
                        label: "disclosure_permission.change_choice",
                        style: .outlined,
                        size: .small,
                        isTransparent: true,
                        onPressed: onChangeChoice,
                      ),
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < credentials.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < credentials.length - 1 ? theme.smallSpacing : 0,
                ),
                child: YiviCredentialCard.fromSelectableInstance(
                  instance: credentials[i],
                  compact: true,
                  hideFooter: true,
                  headerTrailing: i == 0 && optional && onRemove != null
                      ? IrmaIconButton(
                          key: const Key("remove_optional_data_button"),
                          icon: Icons.close,
                          size: 22,
                          padding: .zero,
                          onTap: onRemove!,
                        )
                      : null,
                ),
              ),
          ],
        ),
      );
    }

    // No owned options — show obtainable/missing state
    final obtainable = pickOne.obtainableOptions;
    if (obtainable != null && obtainable.isNotEmpty) {
      return Card(
        margin: .only(bottom: theme.smallSpacing),
        child: Padding(
          padding: .all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: .start,
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
                  padding: .symmetric(vertical: theme.tinySpacing),
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
