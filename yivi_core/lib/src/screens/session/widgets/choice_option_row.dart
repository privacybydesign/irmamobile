import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_summary.dart";
import "../../../widgets/translated_text.dart";

/// Corner radius of the option rows and the card around them.
const choiceOptionRadius = BorderRadius.all(Radius.circular(10));

const _rowLogoSize = 32.0;
const _rowMinHeight = 56.0;
// 10 by 12 px inside a 1 px border, which takes no room in Flutter.
const _rowPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 11);
const _obtainChevronSize = 18.0;

// Above this text scale an option's name breaks mid-word next to its trailing
// widget, so the trailing widget moves below the name.
const _besideTextScaleLimit = 1.5;
const _obtainChevronGap = 2.0;

/// Joins option names into one phrase, e.g. "Paspoort of ID-kaart".
String joinChoiceNames(BuildContext context, Iterable<String> names) {
  final or = FlutterI18n.translate(context, "disclosure_permission.choice.or");
  return names.join(" $or ");
}

/// Joins option names for use inside a sentence, e.g. "paspoort of ID-kaart".
/// [itemKey] is a translation with a `{name}` parameter that each name is put
/// in, for example to add an article.
String joinChoiceNamesInSentence(
  BuildContext context,
  Iterable<String> names, {
  String? itemKey,
}) {
  final language = FlutterI18n.currentLocale(context)?.languageCode;
  final inSentence = names.map((name) {
    final lowered = _lowerFirstLetter(name, language);
    if (itemKey == null) return lowered;

    return FlutterI18n.translate(
      context,
      itemKey,
      translationParams: {"name": lowered},
    );
  });

  return joinChoiceNames(context, inSentence);
}

/// "Paspoort" becomes "paspoort". German capitalises its nouns, and a name
/// with capitals after its first letter, such as ID-kaart or DigiD, keeps
/// them. The same rule as the external issuer heads-up.
String _lowerFirstLetter(String name, String? language) {
  final firstWord = name.split(" ").first;
  if (language == "de" || firstWord.length < 2) return name;

  final afterFirstLetter = firstWord.substring(1);
  if (afterFirstLetter != afterFirstLetter.toLowerCase()) return name;

  return name[0].toLowerCase() + name.substring(1);
}

/// The name of an option to obtain. A bundle of several credentials is named
/// after all of them.
String issuanceBundleName(IssuanceBundle bundle) =>
    bundle.credentials.map((c) => c.name).join(", ");

/// The name of an option in the app, named like [issuanceBundleName].
String disclosureBundleName(DisclosureBundle bundle) =>
    bundle.credentials.map((c) => c.name).join(", ");

/// The distinct names of everything a [DisclosurePickOne] accepts, owned
/// options first. A bundle of several credentials is named after all of them.
List<String> pickOneNames(DisclosurePickOne pickOne) {
  return {
    for (final bundle in pickOne.ownedOptions ?? <DisclosureBundle>[])
      disclosureBundleName(bundle),
    for (final descriptor
        in pickOne.obtainableOptions ?? <CredentialDescriptor>[])
      descriptor.name,
  }.toList();
}

/// An option's [summary] with [trailing] beside it, or below it at large text
/// sizes.
class ChoiceOptionLayout extends StatelessWidget {
  final Widget summary;
  final Widget? trailing;

  const ChoiceOptionLayout({super.key, required this.summary, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final spacing = theme.smallSpacing + theme.tinySpacing;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    if (trailing != null && textScale > _besideTextScaleLimit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing,
        children: [summary, trailing!],
      );
    }

    return Row(
      spacing: spacing,
      children: [
        Expanded(child: summary),
        ?trailing,
      ],
    );
  }
}

/// A row for an option that is not in the app yet: logo, name and
/// "Obtain ›". Without [onTap] the option cannot be obtained from the app, so
/// the row is dimmed and has no hint.
class ChoiceOptionRow extends StatelessWidget {
  final String name;
  final LogoImage? logo;
  final VoidCallback? onTap;

  const ChoiceOptionRow({
    super.key,
    required this.name,
    required this.logo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final row = Material(
      color: theme.light,
      shape: RoundedRectangleBorder(
        borderRadius: choiceOptionRadius,
        side: BorderSide(color: theme.neutralLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _rowMinHeight),
          child: Padding(
            padding: _rowPadding,
            child: ChoiceOptionLayout(
              summary: CredentialSummary(
                name: name,
                nameWeight: FontWeight.w600,
                image: logo,
                logoSize: _rowLogoSize,
              ),
              trailing: onTap != null ? const _ObtainHint() : null,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: onTap != null ? row : Opacity(opacity: 0.5, child: row),
    );
  }
}

class _ObtainHint extends StatelessWidget {
  const _ObtainHint();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TranslatedText(
          "disclosure_permission.choice.obtain",
          style: TextStyle(
            fontFamily: theme.secondaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.link,
          ),
        ),
        const SizedBox(width: _obtainChevronGap),
        ExcludeSemantics(
          child: Icon(
            Icons.chevron_right,
            size: _obtainChevronSize,
            color: theme.link,
          ),
        ),
      ],
    );
  }
}
