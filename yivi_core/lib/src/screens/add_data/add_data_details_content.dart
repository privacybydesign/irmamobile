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
import "../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/sheet_action_row.dart";
import "../../widgets/irma_markdown.dart";

/// What a credential type is, compact for the sheet (its name is in the
/// sheet's bar): a small example card beside "Issued by {issuer}", the intro,
/// what you get as a checklist of its attributes, and the answers to what it
/// is for and how it is added, folded into one group. During a request
/// ([forRequestor]) a note says that only what is asked is shared. The first
/// step of adding a card in a sheet ([IssueFlow]).
/// Which part of the details to show: all of it, or (in the two columns of a
/// sheet held sideways, [SheetSplit]) the card with its name, or the rest.
enum AddDataDetailsPart { all, card, rest }

class AddDataDetailsContent extends StatelessWidget {
  final CredentialDescriptor credential;
  final Faq? faq;

  /// The requestor the card is added for, during a request.
  final String? forRequestor;
  final AddDataDetailsPart part;

  /// The card's width in [AddDataDetailsPart.card].
  final double cardWidth;

  const AddDataDetailsContent({
    super.key,
    required this.credential,
    this.faq,
    this.forRequestor,
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

    final name = <Widget>[
      // What it is, and who gives it.
      Text(
        credential.name,
        key: const Key("add_data_details_name"),
        style: palette
            .body(15, weight: FontWeight.w600)
            .copyWith(height: 21 / 15, color: palette.text),
      ),
      Text(
        credential.issuer.name,
        key: const Key("add_data_details_issuer"),
        style: palette
            .body(13)
            .copyWith(height: 18 / 13, color: palette.secondaryText),
      ),
    ];
    if (part == AddDataDetailsPart.card) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CredentialTypeThumbnail(
              descriptor: credential,
              width: cardWidth,
            ),
          ),
          ...name,
        ],
      );
    }
    // Upright, the card and the intro start where the section labels' text
    // does ("You get").
    final upright = part == AddDataDetailsPart.all && !useSheetColumns(context);
    final inset = upright ? _SectionLabel.inset : 0.0;
    final rest = <Widget>[
      Padding(
        // Starts where the card does.
        padding: EdgeInsets.fromLTRB(
          inset,
          part == AddDataDetailsPart.rest ? 0 : 14,
          inset,
          0,
        ),
        child: Text(
          intro.isNotEmpty
              ? intro
              : context.tr("data.add.details.obtain", {
                  "credential": credential.name,
                }),
          style: palette
              .body(15)
              .copyWith(height: 22 / 15, color: palette.heading),
        ),
      ),
      // What you get: the attributes of the type. The FAQ's own list of
      // them only when the type names none (it repeats them otherwise).
      if (attributeNames.isNotEmpty ||
          content.isNotEmpty ||
          forRequestor != null) ...[
        _SectionLabel(context.tr("data.add.details.you_get")),
        GlassGroup(
          key: const Key("add_data_you_get"),
          children: [
            if (attributeNames.isNotEmpty)
              _Checklist(names: attributeNames)
            else if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _Markdown(content),
              ),
            if (forRequestor case final requestor?)
              _DisclosureNote(requestor: requestor),
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
                peek: purpose.replaceAll("\n\n", " "),
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
    // A phone held sideways: the card large at the left, with its name and
    // issuer under it; what it is and what you get at the right.
    if (useSheetColumns(context)) {
      return SheetColumns(
        startWidth: 250,
        start: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: CredentialTypeThumbnail(
                descriptor: credential,
                width: 250,
              ),
            ),
            ...name,
          ],
        ),
        end: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rest,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room above the card, under the bar.
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Row(
            spacing: 14,
            children: [
              CredentialTypeThumbnail(descriptor: credential, width: 88),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: name,
                ),
              ),
            ],
          ),
        ),
        ...rest,
      ],
    );
  }

  /// "How does it work?": its "1. …" lines as numbered steps, the text
  /// before and after them as paragraphs. Folded, it says how many steps
  /// there are and where they start.
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
    final peek = steps.isEmpty
        ? before.join(" ")
        : FlutterI18n.translate(
            context,
            "data.add.details.steps_peek",
            translationParams: {
              "count": "${steps.length}",
              "first": steps.first.$2,
            },
          );
    return _Fold(
      key: const Key("add_data_howto"),
      question: FlutterI18n.translate(
        context,
        "data.add.details.howto_question",
      ),
      peek: peek,
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

/// The attribute names in two columns, each with a check. Past [shown]
/// names, "Show all n" opens the rest.
class _Checklist extends StatefulWidget {
  final List<String> names;

  const _Checklist({required this.names});

  static const shown = 8;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final names = widget.names;
    final more = !_all && names.length > _Checklist.shown;
    final visible = more ? names.take(_Checklist.shown).toList() : names;
    final rows = [
      for (var i = 0; i < visible.length; i += 2)
        visible.sublist(i, i + 2 > visible.length ? visible.length : i + 2),
    ];

    Widget cell(String name) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: const ToneDisc(
            icon: Icons.check_rounded,
            tone: DialogTone.info,
            size: 18,
            iconSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            name,
            style: palette
                .body(14, weight: FontWeight.w600)
                .copyWith(height: 19 / 14, color: palette.heading),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          key: const Key("add_data_checklist"),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            spacing: 10,
            children: [
              for (final row in rows)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Expanded(child: cell(row[0])),
                    Expanded(
                      child: row.length > 1
                          ? cell(row[1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (more) ...[
          Divider(height: 1, thickness: 1, color: palette.divider),
          InkWell(
            key: const Key("add_data_show_all"),
            onTap: () => setState(() => _all = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                FlutterI18n.translate(
                  context,
                  "data.add.details.show_all",
                  translationParams: {"count": "${names.length}"},
                ),
                style: palette
                    .body(14, weight: FontWeight.w600)
                    .copyWith(color: palette.link),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "You will retrieve all available data…", at the foot of what you get.
class _DisclosureNote extends StatelessWidget {
  final String requestor;

  const _DisclosureNote({required this.requestor});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("add_data_disclosure_note"),
      color: palette.infoSurface,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: palette.link,
            ),
          ),
          Expanded(
            child: _Markdown(
              FlutterI18n.translate(
                context,
                "data.add.details.disclosure_info_requestor",
                translationParams: {"requestor": requestor},
              ),
              size: 13,
              color: palette.noteText,
            ),
          ),
        ],
      ),
    );
  }
}

/// One question, folded: the question and a two-line peek at the answer.
/// A tap opens the whole answer in place.
class _Fold extends StatefulWidget {
  final String question;
  final String peek;
  final Widget child;

  const _Fold({
    super.key,
    required this.question,
    required this.peek,
    required this.child,
  });

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
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.question,
                            style: palette
                                .display(15)
                                .copyWith(height: 21 / 15, color: palette.text),
                          ),
                          if (!_open)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.peek,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: palette
                                    .body(13.5)
                                    .copyWith(
                                      height: 19 / 13.5,
                                      color: palette.secondaryText,
                                    ),
                              ),
                            ),
                        ],
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
        ExcludeSemantics(
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: palette
                  .body(12, weight: FontWeight.w700)
                  .copyWith(color: palette.link, height: 1),
            ),
          ),
        ),
        Expanded(child: _Markdown(text)),
      ],
    );
  }
}

/// An answer's text: markdown, as the store gives it, at the page's size.
class _Markdown extends StatelessWidget {
  final String data;
  final double size;
  final Color? color;

  const _Markdown(this.data, {this.size = 14.5, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = palette
        .body(size)
        .copyWith(height: 21 / 14.5, color: color ?? palette.heading);
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
