import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/radio_indicator.dart";
import "../../../widgets/translated_text.dart";
import "session_scaffold.dart";

/// Submenu screen for choosing between the available options in a [DisclosurePickOne].
///
/// Shows owned credentials first (selectable with radio buttons), then
/// obtainable credentials below. Confirming pops the screen and returns
/// the selected index within the owned options via [onChoiceMade].
class DisclosureMakeChoiceScreen extends StatefulWidget {
  final DisclosurePickOne pickOne;
  final int initialSelectedIndex;
  final ValueChanged<int> onChoiceMade;

  const DisclosureMakeChoiceScreen({
    super.key,
    required this.pickOne,
    required this.initialSelectedIndex,
    required this.onChoiceMade,
  });

  @override
  State<DisclosureMakeChoiceScreen> createState() =>
      _DisclosureMakeChoiceScreenState();
}

class _DisclosureMakeChoiceScreenState
    extends State<DisclosureMakeChoiceScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final owned = widget.pickOne.ownedOptions ?? [];
    final obtainable = widget.pickOne.obtainableOptions ?? [];

    return SessionScaffold(
      appBarTitle: "disclosure_permission.change_choice",
      onPrevious: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owned options — selectable
              for (var i = 0; i < owned.length; i++)
                _OwnedChoiceOption(
                  credential: owned[i],
                  isSelected: i == _selectedIndex,
                  onTap: () => setState(() => _selectedIndex = i),
                ),

              // Obtainable options section
              if (obtainable.isNotEmpty) ...[
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "disclosure_permission.obtain_new",
                  style: theme.themeData.textTheme.headlineMedium,
                  isHeader: true,
                ),
                SizedBox(height: theme.smallSpacing),
                for (final cred in obtainable)
                  _ObtainableCredentialCard(credential: cred),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: owned.isNotEmpty
          ? IrmaBottomBar(
              primaryButtonLabel: "ui.done",
              onPrimaryPressed: () {
                widget.onChoiceMade(_selectedIndex);
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }
}

/// A selectable owned credential option with radio indicator.
class _OwnedChoiceOption extends StatelessWidget {
  final SelectableCredentialInstance credential;
  final bool isSelected;
  final VoidCallback onTap;

  const _OwnedChoiceOption({
    required this.credential,
    required this.isSelected,
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
          style: isSelected ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
              if (credential.attributes.isNotEmpty) ...[
                SizedBox(height: theme.smallSpacing),
                YiviCredentialCardAttributeList(credential.attributes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A non-selectable card showing a credential that can be obtained.
class _ObtainableCredentialCard extends StatelessWidget {
  final CredentialDescriptor credential;

  const _ObtainableCredentialCard({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: IrmaCard(
        style: IrmaCardStyle.outlined,
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
            if (credential.issueURL != null)
              Icon(Icons.open_in_new, size: 20, color: theme.neutralExtraDark),
          ],
        ),
      ),
    );
  }
}
