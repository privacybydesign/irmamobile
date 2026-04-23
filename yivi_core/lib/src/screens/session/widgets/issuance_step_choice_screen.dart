import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/radio_indicator.dart";
import "session_scaffold.dart";

/// Submenu screen for choosing which credential type to obtain in an [IssuanceStep].
///
/// Shows all credential type options with radio buttons. Confirming pops the
/// screen and returns the selected index via [onChoiceMade].
class IssuanceStepChoiceScreen extends StatefulWidget {
  final IssuanceStep step;
  final int stepNumber;
  final int initialSelectedIndex;
  final ValueChanged<int> onChoiceMade;

  const IssuanceStepChoiceScreen({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.initialSelectedIndex,
    required this.onChoiceMade,
  });

  @override
  State<IssuanceStepChoiceScreen> createState() =>
      _IssuanceStepChoiceScreenState();
}

class _IssuanceStepChoiceScreenState extends State<IssuanceStepChoiceScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final options = widget.step.options;

    return SessionScaffold(
      appBarTitle: "disclosure_permission.change_choice",
      onPrevious: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(
                  context,
                  "disclosure.issue_during_disclosure.step",
                  translationParams: {"step": "${widget.stepNumber}"},
                ),
                style: theme.themeData.textTheme.headlineMedium,
              ),
              SizedBox(height: theme.defaultSpacing),
              for (var i = 0; i < options.length; i++)
                _CredentialTypeOption(
                  credential: options[i],
                  isSelected: i == _selectedIndex,
                  onTap: () => setState(() => _selectedIndex = i),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.done",
        onPrimaryPressed: () {
          widget.onChoiceMade(_selectedIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// A selectable credential type card with radio indicator.
class _CredentialTypeOption extends StatelessWidget {
  final CredentialDescriptor credential;
  final bool isSelected;
  final VoidCallback onTap;

  const _CredentialTypeOption({
    required this.credential,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: GestureDetector(
        onTap: onTap,
        child: IrmaCard(
          style: isSelected ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: theme.smallSpacing),
                child: RadioIndicator(isSelected: isSelected),
              ),
              if (credential.image != null)
                Padding(
                  padding: EdgeInsets.only(right: theme.smallSpacing),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: credential.image!.getImageFromBase64(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.name.translate(lang),
                      style: theme.themeData.textTheme.titleSmall,
                    ),
                    Text(
                      credential.issuer.name.translate(lang),
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
