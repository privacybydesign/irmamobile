import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/i18n.dart";
import "../../util/reveal_whole.dart";
import "../../widgets/caps_label.dart";
import "../../widgets/credential_card/card_tile.dart";
import "../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../widgets/flight/yivi_flight.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/sheet_layout.dart";
import "../../widgets/irma_markdown.dart";
import "../../widgets/step_number_disc.dart";

/// Which part of the details to show: all of it, or (in the two columns of a
/// sheet held sideways, [SheetSplit]) the card with its name and the intro,
/// or the rest.
enum AddDataDetailsPart { all, card, rest }

/// What a credential type is, for the sheet: upright the card large and
/// centred, its name and "From {issuer}" under it (the page's heading; the
/// sheet's bar stays empty), the intro, what comes in the app (the card as a
/// tile: its picture, name and issuer, and its fields as a list), and the
/// answers to what it is for and how it is added, folded into one group.
/// The first step of adding a card in a sheet ([IssueFlow]).
class AddDataDetailsContent extends StatelessWidget {
  final CredentialDescriptor credential;
  final Faq? faq;

  /// The hero picture's place, where a card lifted from the share screen
  /// lands ([FlightSpot]).
  final GlobalKey? heroKey;

  /// The name, the page's heading: the bar shows its title once this has
  /// scrolled under it.
  final GlobalKey? titleKey;

  /// What happens when adding it, for Yivi's own ways (an e-mail code, a
  /// document scan); it comes before the store's intro.
  final String? howIntro;
  final AddDataDetailsPart part;

  /// The card's width in [AddDataDetailsPart.card].
  final double cardWidth;

  const AddDataDetailsContent({
    super.key,
    required this.credential,
    this.faq,
    this.heroKey,
    this.titleKey,
    this.howIntro,
    this.part = AddDataDetailsPart.all,
    this.cardWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final faq = this.faq;
    // The store escapes line breaks; in the markdown answers each one starts
    // a paragraph.
    String clean(String? text, {String lineBreak = "\n"}) =>
        (text ?? "").replaceAll("\\n", lineBreak).trim();

    final intro = clean(faq?.intro);
    final purpose = clean(faq?.purpose, lineBreak: "\n\n");
    final content = clean(faq?.content, lineBreak: "\n\n");
    final howTo = clean(faq?.howTo);
    final attributeNames = [
      for (final a in credential.attributes) a.effectiveDisplayName,
    ].where((n) => n.isNotEmpty).toList();

    final introText =
        howIntro ??
        (intro.isNotEmpty
            ? intro
            : context.tr("data.add.details.obtain", {
                "credential": credential.name,
              }));
    final upright = part == AddDataDetailsPart.all && !useSheetColumns(context);
    final introLine = Text(
      introText,
      key: const Key("add_data_details_intro"),
      textAlign: upright ? TextAlign.center : TextAlign.start,
      style: palette.body(15).copyWith(height: 22 / 15, color: palette.heading),
    );
    // Held sideways: the picture (four fifths of the hero), the name, who
    // gives it and the intro, at the left.
    if (part == AddDataDetailsPart.card) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _picture(_heroWidth * 0.8),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              credential.name,
              key: titleKey ?? const Key("add_data_details_name"),
              style: palette
                  .display(24, weight: FontWeight.w700)
                  .copyWith(height: 30 / 24, color: palette.text),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr("data.add.details.from", {
              "issuer": credential.issuer.name,
            }),
            key: const Key("add_data_details_issuer"),
            style: palette
                .body(13)
                .copyWith(height: 18 / 13, color: palette.secondaryText),
          ),
          const SizedBox(height: 12),
          introLine,
        ],
      );
    }
    final inset = upright ? _SectionLabel.inset : 0.0;
    final rest = <Widget>[
      if (part == AddDataDetailsPart.all)
        Padding(
          padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
          child: introLine,
        ),
      // What comes in the app: the card as a tile, its fields under it. The
      // FAQ's own list of them only when the type names none.
      if (attributeNames.isNotEmpty || content.isNotEmpty) ...[
        _SectionLabel(context.tr("data.add.details.you_get")),
        if (attributeNames.isNotEmpty)
          _YouGet(credential: credential, names: attributeNames)
        else
          GlassGroup(
            key: const Key("add_data_you_get"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _Markdown(content),
              ),
            ],
          ),
      ],
      if (purpose.isNotEmpty || howTo.isNotEmpty) ...[
        _SectionLabel(context.tr("data.add.details.good_to_know")),
        GlassGroup(
          children: [
            if (purpose.isNotEmpty)
              _Fold(
                key: const Key("add_data_purpose"),
                question: context.tr("data.add.details.purpose_question"),
                child: _Markdown(purpose),
              ),
            if (howTo.isNotEmpty) _howTo(context, howTo),
          ],
        ),
      ],
    ];

    if (part == AddDataDetailsPart.rest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rest,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_hero(context), ...rest],
    );
  }

  /// The card's picture at [width]: where a card lifted from the share
  /// screen lands.
  Widget _picture(double width) {
    final picture = CredentialTypeThumbnail(
      descriptor: credential,
      width: width,
    );
    final key = heroKey;
    return key == null ? picture : FlightSpot(flightKey: key, child: picture);
  }

  /// The top of the page upright: the card, the card's name as the page's
  /// heading, and "From {issuer}".
  Widget _hero(BuildContext context) {
    final palette = YiviPalette.of(context);
    final issuer = credential.issuer;
    return Column(
      key: const Key("add_data_details_hero"),
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: _picture(_heroWidth),
        ),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            credential.name,
            key: titleKey ?? const Key("add_data_details_name"),
            textAlign: TextAlign.center,
            style: palette
                .display(24, weight: FontWeight.w700)
                .copyWith(height: 30 / 24, color: palette.text),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr("data.add.details.from", {"issuer": issuer.name}),
          key: const Key("add_data_details_issuer"),
          textAlign: TextAlign.center,
          style: palette
              .body(13)
              .copyWith(height: 18 / 13, color: palette.secondaryText),
        ),
      ],
    );
  }

  static const double _heroWidth = 200;

  /// "How does it work?": its "1. …" lines as numbered steps, the text
  /// before and after them as paragraphs.
  Widget _howTo(BuildContext context, String text) {
    final before = <String>[], after = <String>[];
    final steps = <(String, String)>[];
    final step = RegExp(r"^(\d+)\.\s*(.*)$");
    for (final line in text.split("\n").map((l) => l.trim())) {
      if (line.isEmpty) continue;
      final m = step.firstMatch(line);
      if (m != null) {
        steps.add((m.group(1)!, m.group(2)!));
      } else {
        (steps.isEmpty ? before : after).add(line);
      }
    }
    return _Fold(
      key: const Key("add_data_howto"),
      question: FlutterI18n.translate(
        context,
        "data.add.details.howto_question",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final p in before) _Markdown(p),
          for (final (n, s) in steps) _Step(number: n, text: s),
          for (final p in after) _Markdown(p),
        ],
      ),
    );
  }
}

/// The small uppercase label above a group.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  /// Where its text starts, from the edge of the groups.
  static const double inset = 10;

  @override
  Widget build(BuildContext context) =>
      CapsLabel(text, padding: const EdgeInsets.fromLTRB(inset, 20, inset, 8));
}

/// What comes in the app: the card as a tile (its picture, name and
/// issuer, as on the share screen), a line, and its fields as a list.
class _YouGet extends StatelessWidget {
  final CredentialDescriptor credential;
  final List<String> names;

  const _YouGet({required this.credential, required this.names});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return CardTile(
      key: const Key("add_data_you_get"),
      art: CredentialTypeThumbnail(
        descriptor: credential,
        width: CardTile.miniWidth,
      ),
      title: credential.name,
      subtitle: credential.issuer.name,
      body: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              key: const Key("add_data_checklist"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final n in names)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      spacing: 10,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.link.withValues(alpha: 0.32),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            n,
                            style: palette
                                .body(15)
                                .copyWith(height: 21 / 15, color: palette.text),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Fold extends StatefulWidget {
  final String question;
  final Widget child;

  const _Fold({super.key, required this.question, required this.child});

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  bool _open = false;

  /// Opened: once it has grown, the whole answer in view (the sheet's
  /// content starts under its bar, so nothing is covered at the top).
  Future<void> _toggle(Duration grow) async {
    setState(() => _open = !_open);
    if (!_open) return;
    await Future<void>.delayed(grow);
    if (mounted) revealWhole(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final duration = YiviMotion.duration(
      context,
      const Duration(milliseconds: 220),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => _toggle(duration),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: palette
                            .display(15)
                            .copyWith(height: 21 / 15, color: palette.text),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// One numbered step of "How does it work?".
class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        StepNumberDisc(
          number,
          size: 22,
          style: palette
              .body(12, weight: FontWeight.w700)
              .copyWith(color: palette.link, height: 1),
        ),
        Expanded(child: _Markdown(text)),
      ],
    );
  }
}

/// An answer's text: markdown, as the store gives it, at the page's size.
class _Markdown extends StatelessWidget {
  final String data;

  const _Markdown(this.data);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = palette
        .body(14.5)
        .copyWith(height: 21 / 14.5, color: palette.heading);
    return IrmaMarkdown(
      data,
      styleSheet: MarkdownStyleSheet(
        p: style,
        listBullet: style,
        strong: style.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
