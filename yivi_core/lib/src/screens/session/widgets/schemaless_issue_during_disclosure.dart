import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_quote.dart";
import "../../../widgets/yivi_themed_button.dart";
import "issuance_step_choice_screen.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// Each step may have multiple credential type options. When a step has more
/// than one option, the user can tap to open a submenu and pick one.
class SchemalessIssueDuringDisclosure extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;

  const SchemalessIssueDuringDisclosure({
    super.key,
    required this.sessionState,
    required this.onDismiss,
  });

  @override
  State<SchemalessIssueDuringDisclosure> createState() =>
      _SchemalessIssueDuringDisclosureState();
}

class _SchemalessIssueDuringDisclosureState
    extends State<SchemalessIssueDuringDisclosure> {
  late List<int> _selectedOptionPerStep;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  @override
  void didUpdateWidget(SchemalessIssueDuringDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionState != widget.sessionState) {
      _initializeSelections();
    }
  }

  void _initializeSelections() {
    final steps =
        widget.sessionState.disclosurePlan?.issueDuringDislosure?.steps ?? [];
    _selectedOptionPerStep = List.generate(steps.length, (_) => 0);
  }

  void _onChangeOption(int stepIndex) {
    final steps =
        widget.sessionState.disclosurePlan!.issueDuringDislosure!.steps;
    if (stepIndex >= steps.length) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssuanceStepChoiceScreen(
          step: steps[stepIndex],
          stepNumber: stepIndex + 1,
          initialSelectedIndex: _selectedOptionPerStep[stepIndex],
          onChoiceMade: (newIndex) {
            setState(() => _selectedOptionPerStep[stepIndex] = newIndex);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final steps =
        widget.sessionState.disclosurePlan!.issueDuringDislosure!.steps;
    final requestorName = widget.sessionState.requestor.name.translate(lang);

    return SessionScaffold(
      appBarTitle: "disclosure.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: "session.navigation_bar.cancel",
        onSecondaryPressed: widget.onDismiss,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        children: [
          IrmaQuote(
            quote: FlutterI18n.translate(
              context,
              "disclosure.issue_during_disclosure.instruction",
              translationParams: {"requestor": requestorName},
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
          for (final (index, step) in steps.indexed)
            _IssuanceStepCard(
              step: step,
              stepNumber: index + 1,
              selectedOptionIndex: _selectedOptionPerStep[index],
              hasMultipleOptions: step.options.length > 1,
              onChangeOption: () => _onChangeOption(index),
            ),
        ],
      ),
    );
  }
}

class _IssuanceStepCard extends StatelessWidget {
  final IssuanceStep step;
  final int stepNumber;
  final int selectedOptionIndex;
  final bool hasMultipleOptions;
  final VoidCallback onChangeOption;

  const _IssuanceStepCard({
    required this.step,
    required this.stepNumber,
    required this.selectedOptionIndex,
    required this.hasMultipleOptions,
    required this.onChangeOption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final selectedOption = step.options[selectedOptionIndex];

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FlutterI18n.translate(
                  context,
                  "disclosure.issue_during_disclosure.step",
                  translationParams: {"step": "$stepNumber"},
                ),
                style: theme.themeData.textTheme.titleMedium,
              ),
              if (hasMultipleOptions)
                YiviThemedButton(
                  label: "disclosure_permission.change_choice",
                  style: YiviButtonStyle.outlined,
                  size: YiviButtonSize.small,
                  isTransparent: true,
                  onPressed: onChangeOption,
                ),
            ],
          ),
          SizedBox(height: theme.smallSpacing),
          _CredentialTypeCard(credential: selectedOption),
        ],
      ),
    );
  }
}

class _CredentialTypeCard extends StatelessWidget {
  final CredentialDescriptor credential;

  const _CredentialTypeCard({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      child: Row(
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
    );
  }
}
