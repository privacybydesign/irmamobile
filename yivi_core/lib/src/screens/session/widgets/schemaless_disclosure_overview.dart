import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/attribute.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../models/session_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/credential_card/schemaless_yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_quote.dart";
import "session_scaffold.dart";

class SchemalessDisclosureOverview extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;

  const SchemalessDisclosureOverview({
    super.key,
    required this.sessionState,
    required this.onDismiss,
  });

  @override
  State<SchemalessDisclosureOverview> createState() =>
      _SchemalessDisclosureOverviewState();
}

class _SchemalessDisclosureOverviewState
    extends State<SchemalessDisclosureOverview> {
  late List<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  @override
  void didUpdateWidget(SchemalessDisclosureOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionState != widget.sessionState) {
      _initializeSelections();
    }
  }

  void _initializeSelections() {
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];
    _selectedIndices = List.generate(choices.length, (_) => 0);
  }

  void _onApprove() {
    final repo = IrmaRepositoryProvider.of(context);
    final choices =
        widget.sessionState.disclosurePlan?.disclosureChoicesOverview ?? [];

    final disclosureChoices = <List<AttributeIdentifier>>[];
    for (var i = 0; i < choices.length; i++) {
      final pickOne = choices[i];
      final owned = pickOne.ownedOptions;
      if (owned != null && owned.isNotEmpty) {
        final selected = owned[_selectedIndices[i]];
        disclosureChoices.add(
          selected.attributes
              .map(
                (attr) => AttributeIdentifier(
                  type: attr.id,
                  credentialHash: selected.hash,
                ),
              )
              .toList(),
        );
      } else {
        disclosureChoices.add([]);
      }
    }

    repo.bridgedDispatch(
      RespondPermissionEvent(
        sessionId: widget.sessionState.id,
        granted: true,
        disclosureChoices: disclosureChoices,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final session = widget.sessionState;
    final choices = session.disclosurePlan?.disclosureChoicesOverview ?? [];
    final isSignature = session.type == SessionType.signature;

    return SessionScaffold(
      appBarTitle: isSignature ? "disclosure.title" : "disclosure.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(
          context,
          isSignature
              ? "disclosure.navigation_bar.sign"
              : "disclosure.navigation_bar.yes",
        ),
        onPrimaryPressed: _onApprove,
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "session.navigation_bar.cancel",
        ),
        onSecondaryPressed: widget.onDismiss,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        children: [
          IrmaQuote(
            quote: FlutterI18n.translate(
              context,
              isSignature
                  ? "disclosure.signing_instruction"
                  : "disclosure.instruction",
              translationParams: {
                "requestor": session.requestor.name.translate(lang),
              },
            ),
          ),
          if (isSignature && session.messageToSign != null) ...[
            SizedBox(height: theme.defaultSpacing),
            Card(
              child: Padding(
                padding: EdgeInsets.all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FlutterI18n.translate(
                        context,
                        "disclosure.message_to_sign",
                      ),
                      style: theme.themeData.textTheme.titleMedium,
                    ),
                    SizedBox(height: theme.smallSpacing),
                    Text(session.messageToSign!),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: theme.defaultSpacing),
          for (var i = 0; i < choices.length; i++)
            _DisclosurePickOneWidget(
              pickOne: choices[i],
              selectedIndex: _selectedIndices[i],
              onSelected: (index) =>
                  setState(() => _selectedIndices[i] = index),
            ),
        ],
      ),
    );
  }
}

class _DisclosurePickOneWidget extends StatelessWidget {
  final DisclosurePickOne pickOne;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DisclosurePickOneWidget({
    required this.pickOne,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = pickOne.ownedOptions;

    if (owned != null && owned.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < owned.length; i++)
            _SelectableCredentialCard(
              credential: owned[i],
              isSelected: i == selectedIndex,
              showRadio: owned.length > 1,
              onTap: () => onSelected(i),
            ),
          SizedBox(height: theme.smallSpacing),
        ],
      );
    }

    // No owned options - show obtainable/missing state
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

class _SelectableCredentialCard extends StatelessWidget {
  final SelectableCredentialInstance credential;
  final bool isSelected;
  final bool showRadio;
  final VoidCallback onTap;

  const _SelectableCredentialCard({
    required this.credential,
    required this.isSelected,
    required this.showRadio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: GestureDetector(
        onTap: onTap,
        child: IrmaCard(
          style: isSelected ? .highlighted : .normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showRadio)
                    Padding(
                      padding: EdgeInsets.only(right: theme.smallSpacing),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? theme.themeData.primaryColor : null,
                      ),
                    ),
                  if (credential.imagePath.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(right: theme.smallSpacing),
                      child: Image.asset(
                        credential.imagePath,
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
                SchemalessYiviCredentialCardAttributeList(
                  credential.attributes,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
