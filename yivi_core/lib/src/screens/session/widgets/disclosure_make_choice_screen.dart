import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:url_launcher/url_launcher.dart";

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

/// Selection type: either an owned credential (by index) or an obtainable one.
sealed class _Selection {
  const _Selection();
}

class _OwnedSelection extends _Selection {
  final int index;
  const _OwnedSelection(this.index);
}

class _ObtainableSelection extends _Selection {
  final int index;
  const _ObtainableSelection(this.index);
}

/// Submenu screen for choosing between the available options in a [DisclosurePickOne].
///
/// Shows owned credentials first (selectable with radio buttons), then
/// obtainable credentials below. When an owned option is selected, the bottom
/// bar shows a "Done" button. When an obtainable option is selected, it shows
/// an "Obtain data" button that opens the issue URL.
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
  late _Selection _selection;

  @override
  void initState() {
    super.initState();
    _selection = _OwnedSelection(widget.initialSelectedIndex);
  }

  bool get _isOwnedSelected => _selection is _OwnedSelection;

  Future<void> _onObtainData() async {
    if (_selection is! _ObtainableSelection) return;
    final obtainable = widget.pickOne.obtainableOptions ?? [];
    final index = (_selection as _ObtainableSelection).index;
    if (index >= obtainable.length) return;

    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final url = obtainable[index].issueURL?.translate(lang);
    if (url != null && url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
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
                  isSelected:
                      _selection is _OwnedSelection &&
                      (_selection as _OwnedSelection).index == i,
                  onTap: () =>
                      setState(() => _selection = _OwnedSelection(i)),
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
                for (var i = 0; i < obtainable.length; i++)
                  _ObtainableChoiceOption(
                    credential: obtainable[i],
                    isSelected:
                        _selection is _ObtainableSelection &&
                        (_selection as _ObtainableSelection).index == i,
                    onTap: () =>
                        setState(() => _selection = _ObtainableSelection(i)),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: _isOwnedSelected
            ? "ui.done"
            : "disclosure_permission.obtain_data",
        onPrimaryPressed: _isOwnedSelected
            ? () {
                widget.onChoiceMade((_selection as _OwnedSelection).index);
                Navigator.of(context).pop();
              }
            : _onObtainData,
      ),
    );
  }
}

/// A selectable owned credential option with radio indicator on the top right.
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  RadioIndicator(isSelected: isSelected),
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

/// A selectable obtainable credential option with radio indicator on the top right.
class _ObtainableChoiceOption extends StatelessWidget {
  final CredentialDescriptor credential;
  final bool isSelected;
  final VoidCallback onTap;

  const _ObtainableChoiceOption({
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              RadioIndicator(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}
