import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_stepper.dart";
import "../../../widgets/radio_indicator.dart";
import "../../../widgets/session_progress_indicator.dart";
import "../../../widgets/translated_text.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// Uses [IrmaStepper] to display steps as a timeline, matching the visual
/// style from the old disclosure permission issue wizard.
class IssueDuringDisclosureScreen extends ConsumerStatefulWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;

  const IssueDuringDisclosureScreen({
    super.key,
    required this.sessionState,
    required this.onDismiss,
  });

  @override
  ConsumerState<IssueDuringDisclosureScreen> createState() =>
      _IssueDuringDisclosureScreenState();
}

class _IssueDuringDisclosureScreenState
    extends ConsumerState<IssueDuringDisclosureScreen> {
  late List<int> _selectedOptionPerStep;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  @override
  void didUpdateWidget(IssueDuringDisclosureScreen oldWidget) {
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

  /// Returns true if any of the step's credential options have been issued.
  bool _isStepCompleted(IssuanceStep step) {
    final issued = widget
        .sessionState
        .disclosurePlan
        ?.issueDuringDislosure
        ?.issuedCredentialIds;
    if (issued == null || issued.isEmpty) return false;
    return step.options.any((opt) => issued.containsKey(opt.credentialId));
  }

  /// Returns the index of the first step that hasn't been completed yet,
  /// or null if all steps are completed.
  int? _findCurrentStepIndex(List<IssuanceStep> steps) {
    for (var i = 0; i < steps.length; i++) {
      if (!_isStepCompleted(steps[i])) return i;
    }
    return null;
  }

  Future<void> _onObtainData(CredentialDescriptor credential) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final url = credential.issueURL?.translate(lang);
    if (url != null && url.isNotEmpty) {
      ref
          .read(irmaRepositoryProvider)
          .openIssueURL(
            context,
            credential.credentialId,
            credential.issueURL,
            ref,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final steps =
        widget.sessionState.disclosurePlan!.issueDuringDislosure!.steps;

    final currentStepIndex = _findCurrentStepIndex(steps);
    final isCompleted = currentStepIndex == null;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.issue_wizard.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: isCompleted
            ? "disclosure_permission.next_step"
            : "disclosure_permission.obtain_data",
        onPrimaryPressed: isCompleted
            ? widget.onDismiss
            : () {
                _onObtainData(
                  steps[currentStepIndex]
                      .options[_selectedOptionPerStep[currentStepIndex]],
                );
              },
        secondaryButtonLabel: "session.navigation_bar.cancel",
        onSecondaryPressed: widget.onDismiss,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SessionProgressIndicator(
                step: isCompleted ? steps.length : currentStepIndex + 1,
                stepCount: steps.length,
                contentTranslationKey: isCompleted
                    ? "disclosure_permission.issue_wizard.explanation_complete"
                    : "disclosure_permission.issue_wizard.explanation_incomplete",
              ),
              SizedBox(height: theme.defaultSpacing),
              IrmaStepper(
                currentIndex: currentStepIndex,
                children: [
                  for (final (index, step) in steps.indexed)
                    _buildStepContent(theme, step, index, currentStepIndex),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(
    IrmaThemeData theme,
    IssuanceStep step,
    int index,
    int? currentStepIndex,
  ) {
    final isCurrent = index == currentStepIndex;

    // Step with multiple options: show choice with radio buttons
    if (step.options.length > 1 && isCurrent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(theme.smallSpacing),
            child: TranslatedText(
              "disclosure_permission.choose",
              style: theme.themeData.textTheme.headlineMedium,
            ),
          ),
          for (var i = 0; i < step.options.length; i++)
            _CredentialTypeCard(
              credential: step.options[i],
              isHighlighted: true,
              showRadio: true,
              isSelected: i == _selectedOptionPerStep[index],
              onTap: () => setState(() => _selectedOptionPerStep[index] = i),
            ),
        ],
      );
    }

    // Single option (or non-current multi-option): show selected credential card
    return _CredentialTypeCard(
      credential: step.options[_selectedOptionPerStep[index]],
      isHighlighted: isCurrent,
    );
  }
}

class _CredentialTypeCard extends StatelessWidget {
  final CredentialDescriptor credential;
  final bool isHighlighted;
  final bool showRadio;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CredentialTypeCard({
    required this.credential,
    this.isHighlighted = false,
    this.showRadio = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: GestureDetector(
        onTap: onTap,
        child: IrmaCard(
          style: isHighlighted ? .highlighted : .normal,
          child: Row(
            children: [
              if (showRadio)
                Padding(
                  padding: EdgeInsets.only(right: theme.smallSpacing),
                  child: RadioIndicator(isSelected: isSelected),
                ),
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
        ),
      ),
    );
  }
}
