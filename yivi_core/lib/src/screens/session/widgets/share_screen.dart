import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_action_card.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/requestor_header.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "share_credential_card.dart";
import "share_trust_bar.dart";

/// Whether [session] gets the share screen. Only a disclosure does: signing
/// and issuance keep their own screens.
bool usesShareScreen(WidgetRef ref, SessionState session) {
  if (session.type != SessionType.disclosure) return false;

  return ref.watch(featureFlagProvider(FeatureFlag.shareScreenV2)).value ??
      false;
}

/// A choice of the request as shown on the share screen.
class ShareChoice {
  final DisclosurePickOne pickOne;
  final int selectedIndex;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  const ShareChoice({
    required this.pickOne,
    required this.selectedIndex,
    this.onChange,
    this.onRemove,
  });
}

/// The share screen of a disclosure: no app bar, the credentials with the
/// issuer, and the trust bar above the share button.
class ShareScreen extends StatelessWidget {
  final TrustedParty requestor;
  final List<ShareChoice> requiredChoices;
  final List<ShareChoice> optionalChoices;
  final VoidCallback? onAddOptional;
  final ValueChanged<SelectableCredentialInstance> onShowDetails;
  final VoidCallback? onShare;
  final VoidCallback onDismiss;
  final Widget? progressIndicator;

  const ShareScreen({
    super.key,
    required this.requestor,
    required this.requiredChoices,
    required this.optionalChoices,
    required this.onAddOptional,
    required this.onShowDetails,
    required this.onShare,
    required this.onDismiss,
    this.progressIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final nothingToShare = requiredChoices.isEmpty && optionalChoices.isEmpty;

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IrmaCloseButton(onTap: onDismiss),
              ),
              ShareRequestorHeader(requestor: requestor),
              SizedBox(height: theme.mediumSpacing),
              if (progressIndicator != null) ...[
                progressIndicator!,
                SizedBox(height: theme.defaultSpacing),
              ],
              for (final choice in requiredChoices)
                _ShareChoiceEntry(choice: choice, onShowDetails: onShowDetails),
              if (optionalChoices.isNotEmpty) ...[
                TranslatedText(
                  "disclosure_permission.optional_data",
                  style: theme.textTheme.headlineMedium,
                ),
                SizedBox(height: theme.smallSpacing),
                for (final choice in optionalChoices)
                  _ShareChoiceEntry(
                    choice: choice,
                    onShowDetails: onShowDetails,
                  ),
              ],
              if (nothingToShare)
                TranslatedText(
                  "disclosure_permission.no_data_selected",
                  style: theme.textTheme.headlineMedium,
                ),
              if (onAddOptional != null)
                IrmaActionCard(
                  titleKey: "disclosure_permission.add_optional_data",
                  icon: Icons.add_circle,
                  isFancy: false,
                  onTap: onAddOptional,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBarBase(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: theme.smallSpacing,
          children: [
            ShareTrustBar(requestor: requestor),
            YiviThemedButton(
              key: const Key("bottom_bar_primary"),
              label: "disclosure_permission.share_v2.share",
              onPressed: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareChoiceEntry extends StatelessWidget {
  final ShareChoice choice;
  final ValueChanged<SelectableCredentialInstance> onShowDetails;

  const _ShareChoiceEntry({required this.choice, required this.onShowDetails});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = choice.pickOne.ownedOptions;

    if (owned != null && owned.isNotEmpty) {
      final credentials = owned[choice.selectedIndex].credentials;

      return Padding(
        padding: .only(bottom: theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: theme.smallSpacing,
          children: [
            if (choice.onChange != null)
              Align(
                alignment: Alignment.centerRight,
                child: YiviThemedButton(
                  label: "disclosure_permission.change_choice",
                  style: .outlined,
                  size: .small,
                  isTransparent: true,
                  onPressed: choice.onChange,
                ),
              ),
            for (final (index, credential) in credentials.indexed)
              ShareCredentialCard(
                instance: credential,
                onShowDetails: () => onShowDetails(credential),
                trailing: index == 0 && choice.onRemove != null
                    ? IrmaIconButton(
                        key: const Key("remove_optional_data_button"),
                        icon: Icons.close,
                        size: 22,
                        padding: .zero,
                        onTap: choice.onRemove!,
                      )
                    : null,
              ),
          ],
        ),
      );
    }

    final obtainable = choice.pickOne.obtainableOptions;
    if (obtainable == null || obtainable.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: .only(bottom: theme.smallSpacing),
      child: Padding(
        padding: .all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              FlutterI18n.translate(context, "disclosure.missing_credential"),
              style: theme.textTheme.titleMedium?.copyWith(color: theme.error),
            ),
            SizedBox(height: theme.smallSpacing),
            for (final credential in obtainable)
              Padding(
                padding: .symmetric(vertical: theme.tinySpacing),
                child: Text(credential.name, style: theme.textTheme.bodyLarge),
              ),
          ],
        ),
      ),
    );
  }
}
