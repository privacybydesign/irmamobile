import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_summary.dart";
import "../../../widgets/translated_text.dart";
import "choice_option_row.dart";

const _barrierColor = Color(0x73000000);
const _sheetRadius = Radius.circular(16);
const _sheetSidePadding = 20.0;
const _handleWidth = 40.0;
const _handleHeight = 4.0;
const _optionLogoSize = 36.0;
const _optionMinHeight = 64.0;
const _currentBorderWidth = 2.0;
// 12 px inside a 1 px border. A border takes no room in Flutter, so the
// thicker border of the current option does not move the content either.
const _optionPadding = 13.0;
const _currentColor = Color(0xFFF4F8FC);
const _presentColor = Color(0xFF00602A);
const _obtainButtonHeight = 40.0;

/// Opens the sheet in which the user picks what to share for the
/// [DisclosurePickOne] at [disconIndex]. A tap on an owned option calls
/// [onChoiceMade] with its index in `ownedOptions` and closes the sheet.
///
/// The sheet stays open while an option is obtained through [onObtain].
/// [onSelected] is called whenever a bundle becomes selected for this choice,
/// including the one the app selects after the credential was obtained.
Future<void> showDisclosureChoiceSheet({
  required BuildContext context,
  required DisclosurePickOne pickOne,
  required int sessionId,
  required int disconIndex,
  required String requestorName,
  required ValueChanged<int> onChoiceMade,
  required ValueChanged<CredentialDescriptor> onObtain,
  VoidCallback? onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: _barrierColor,
    builder: (_) => _DisclosureChoiceSheet(
      pickOne: pickOne,
      sessionId: sessionId,
      disconIndex: disconIndex,
      requestorName: requestorName,
      onChoiceMade: onChoiceMade,
      onObtain: onObtain,
      onSelected: onSelected,
    ),
  );
}

/// Content of the sheet from [showDisclosureChoiceSheet]: the owned options
/// with the current one highlighted, then the options that are not in the app
/// yet, each with an "Obtain" button. There is no confirm button.
class _DisclosureChoiceSheet extends ConsumerWidget {
  final DisclosurePickOne pickOne;
  final int sessionId;
  final int disconIndex;
  final String requestorName;
  final ValueChanged<int> onChoiceMade;
  final ValueChanged<CredentialDescriptor> onObtain;
  final VoidCallback? onSelected;

  const _DisclosureChoiceSheet({
    required this.pickOne,
    required this.sessionId,
    required this.disconIndex,
    required this.requestorName,
    required this.onChoiceMade,
    required this.onObtain,
    this.onSelected,
  });

  /// The index in [owned] of the bundle the user has selected, matched by
  /// credential hashes like the share screen does. Defaults to 0.
  static int _currentIndex(
    List<DisclosureBundle> owned,
    DisclosureBundle? selected,
  ) {
    if (selected == null) return 0;

    final hashes = selected.credentialHashes;
    final index = owned.indexWhere(
      (b) =>
          b.credentialHashes.length == hashes.length &&
          b.credentialHashes.containsAll(hashes),
    );
    return index < 0 ? 0 : index;
  }

  /// The values of a bundle, which tell apart options with the same name,
  /// such as two e-mail addresses.
  static String _bundleValues(DisclosureBundle bundle) => [
    for (final credential in bundle.credentials)
      for (final attribute in credential.attributes)
        ?(attribute.value?.string ?? attribute.value?.intValue?.toString()),
  ].join(", ");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final selectedBundle = sessionUserChoicesProvider(
      sessionId,
    ).select((choices) => choices.disclosureChoices[disconIndex]);

    ref.listen(selectedBundle, (previous, next) {
      if (next != null && next != previous) onSelected?.call();
    });

    // The session gets new owned options while the sheet is open once a
    // credential has been obtained, so prefer its live state.
    final choices = ref
        .watch(sessionStateProvider(sessionId))
        .value
        ?.disclosurePlan
        ?.disclosureChoicesOverview;
    final live = choices != null && disconIndex < choices.length
        ? choices[disconIndex]
        : pickOne;
    final owned = live.ownedOptions ?? [];
    final obtainable = live.obtainableOptions ?? [];

    final currentIndex = _currentIndex(owned, ref.watch(selectedBundle));
    final ownedNames = owned.map(disclosureBundleName).toList();

    void pick(int index) {
      onChoiceMade(index);
      Navigator.of(context).pop();
    }

    final gap = theme.smallSpacing + theme.tinySpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: const BorderRadius.vertical(top: _sheetRadius),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: theme.largeSpacing),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: _sheetSidePadding,
            right: _sheetSidePadding,
            top: gap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              SizedBox(height: gap + theme.smallSpacing),
              TranslatedText(
                "disclosure_permission.choice.sheet_title",
                isHeader: true,
                style: TextStyle(
                  fontFamily: theme.primaryFontFamily,
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w700,
                  color: theme.neutralExtraDark,
                ),
              ),
              SizedBox(height: gap),
              TranslatedText(
                "disclosure_permission.choice.sheet_explanation",
                translationParams: {
                  "requestor": requestorName,
                  "options": joinChoiceNamesInSentence(
                    context,
                    pickOneNames(live),
                    itemKey: "disclosure_permission.choice.accepted_option",
                  ),
                },
                style: TextStyle(
                  fontFamily: theme.secondaryFontFamily,
                  fontSize: 15,
                  height: 22 / 15,
                  color: theme.neutralExtraDark,
                ),
              ),
              SizedBox(height: gap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.smallSpacing,
                children: [
                  for (var i = 0; i < owned.length; i++)
                    _OwnedOption(
                      key: Key("choice_sheet_option_$i"),
                      name: ownedNames[i],
                      logo: owned[i].credentials.firstOrNull?.image,
                      // Options with the same name are told apart by value.
                      values:
                          ownedNames.where((n) => n == ownedNames[i]).length > 1
                          ? _bundleValues(owned[i])
                          : null,
                      mark: i == currentIndex ? _Mark.current : _Mark.none,
                      onTap: () => pick(i),
                    ),
                  for (final descriptor in obtainable)
                    _ObtainableOption(
                      descriptor: descriptor,
                      onObtain: descriptor.issueURL != null
                          ? () => onObtain(descriptor)
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Center(
      child: Container(
        width: _handleWidth,
        height: _handleHeight,
        decoration: BoxDecoration(
          color: theme.neutralLight,
          borderRadius: BorderRadius.circular(_handleHeight / 2),
        ),
      ),
    );
  }
}

/// Whether an option is the one that is shared now.
enum _Mark { current, none }

/// The frame of an option: logo, name with a line under it, and [trailing].
class _OptionTile extends StatelessWidget {
  final String name;
  final LogoImage? logo;
  final Widget subtitle;
  final _Mark mark;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.name,
    required this.logo,
    required this.subtitle,
    this.mark = _Mark.none,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final current = mark == _Mark.current;

    return Material(
      color: current ? _currentColor : theme.light,
      shape: RoundedRectangleBorder(
        borderRadius: choiceOptionRadius,
        side: current
            ? BorderSide(color: theme.link, width: _currentBorderWidth)
            : BorderSide(color: theme.neutralLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _optionMinHeight),
          child: Padding(
            padding: const EdgeInsets.all(_optionPadding),
            child: ChoiceOptionLayout(
              summary: CredentialSummary(
                name: name,
                nameWeight: FontWeight.w600,
                image: logo,
                logoSize: _optionLogoSize,
                subtitle: subtitle,
              ),
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}

/// An option in the app: a tap picks it.
class _OwnedOption extends StatelessWidget {
  final String name;
  final LogoImage? logo;
  final String? values;
  final _Mark mark;
  final VoidCallback onTap;

  const _OwnedOption({
    super.key,
    required this.name,
    required this.logo,
    required this.values,
    required this.mark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final text = values;

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: mark == _Mark.current,
      child: _OptionTile(
        name: name,
        logo: logo,
        mark: mark,
        onTap: onTap,
        subtitle: text != null
            ? Text(text, style: credentialSubtitleStyle(theme))
            : TranslatedText(
                "missing_data.status.present",
                style: credentialSubtitleStyle(
                  theme,
                ).copyWith(fontWeight: FontWeight.w600, color: _presentColor),
              ),
      ),
    );
  }
}

/// An option that is not in the app yet, with a button to obtain it. Without
/// [onObtain] it cannot be obtained from the app, so it is dimmed and has no
/// button.
class _ObtainableOption extends StatelessWidget {
  final CredentialDescriptor descriptor;
  final VoidCallback? onObtain;

  const _ObtainableOption({required this.descriptor, required this.onObtain});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final obtain = onObtain;

    final tile = _OptionTile(
      name: descriptor.name,
      logo: descriptor.image,
      subtitle: TranslatedText(
        "missing_data.status.missing",
        style: credentialSubtitleStyle(theme),
      ),
      trailing: obtain != null
          ? _ObtainButton(name: descriptor.name, onPressed: obtain)
          : null,
    );

    return Semantics(
      container: true,
      child: obtain != null
          ? tile
          : Opacity(opacity: choiceUnavailableOpacity, child: tile),
    );
  }
}

class _ObtainButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;

  const _ObtainButton({required this.name, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // Name the credential, so the buttons of different options can be told
    // apart.
    return Semantics(
      key: Key("choice_sheet_obtain_$name"),
      container: true,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      label: FlutterI18n.translate(
        context,
        "missing_data.obtain_named",
        translationParams: {"credential": name},
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, _obtainButtonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: theme.smallSpacing + theme.tinySpacing,
          ),
          foregroundColor: theme.neutralExtraDark,
          backgroundColor: theme.light,
          side: BorderSide(color: theme.neutralExtraDark),
          shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
          textStyle: TextStyle(
            fontFamily: theme.secondaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: TranslatedText("disclosure_permission.choice.obtain"),
      ),
    );
  }
}
