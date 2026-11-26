import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/feedback/progress_part.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/layout/fill_scroll_view.dart";
import "../layout/session_scaffold.dart";
import "../models/disclosure_plan_view.dart";
import "../models/technical_details.dart";
import "../requestor/requestor_card.dart";
import "../requestor/requestor_trust_sheet.dart";
import "disclosure_keys.dart";
import "disclosure_words.dart";

/// "Eerst toevoegen" (2.1): the required choices that could not be answered
/// when the request opened ([fixed]), one row each, with what to add; done
/// rows stay, with a check. The bottom button does the next open row's
/// action, and once everything is in, "Bekijk wat je deelt" ([onReview]).
/// When a required card cannot be added from Yivi, only what stops the
/// request is listed and the button closes it (2.10).
class AddFirstPage extends ConsumerWidget {
  final SessionState session;
  final List<int> fixed;
  final VoidCallback onDismiss;

  /// Ends the session without asking ("Sluiten", "Niet delen").
  final VoidCallback onClose;

  /// "Bekijk wat je deelt".
  final VoidCallback onReview;

  /// Adds for choice [choice]: [way] when there is one, else the picker.
  final void Function(int choice, AddWay? way) onAdd;

  /// Per choice, where its row's picture is: an added card lands there.
  final GlobalKey Function(int choice) landingKey;

  const AddFirstPage({
    super.key,
    required this.session,
    required this.fixed,
    required this.onDismiss,
    required this.onClose,
    required this.onReview,
    required this.onAdd,
    required this.landingKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final plan = session.disclosurePlan ?? DisclosurePlan(choices: const []);
    final wallet = ref.watch(walletCardsProvider);
    final requestor = session.requestor.name;
    final signing = session.type == SessionType.signature;
    final sign = signing ? "_sign" : "";
    final rows = addStepRows(plan, fixed, wallet: wallet);
    final header = addStepHeader(plan, fixed, wallet: wallet);
    final next = nextAction(plan, fixed, wallet: wallet);
    final count = countWord(context, header.count);

    final title = switch (header.title) {
      AddStepTitle.cards when header.count == 1 => t("share.addstep.title_one"),
      AddStepTitle.cards => t("share.addstep.title_many", {"count": count}),
      AddStepTitle.things => t("share.addstep.title_things"),
      AddStepTitle.done => t("share.addstep.title_done"),
      AddStepTitle.otherValue => t("share.addstep.other_title"),
      AddStepTitle.blocked => t("share.blocked.title$sign"),
    };
    final lead = switch (header.title) {
      AddStepTitle.blocked => t("share.blocked.lead", {"requestor": requestor}),
      AddStepTitle.otherValue => t("share.addstep.other_lead", {
        "requestor": requestor,
      }),
      AddStepTitle.done => t("share.addstep.lead_done$sign", {
        "requestor": requestor,
      }),
      _ => t("share.addstep.lead$sign", {"requestor": requestor}),
    };
    final left = countWord(context, header.left);
    final line = switch (header.line) {
      AddStepLine.cardsLeft when header.left == 1 => t(
        "share.addstep.line_one",
      ),
      AddStepLine.cardsLeft => t("share.addstep.line_many", {"count": left}),
      AddStepLine.thingsLeft when header.left == 1 => t(
        "share.addstep.line_thing",
      ),
      AddStepLine.thingsLeft => t("share.addstep.line_things", {"count": left}),
      AddStepLine.done => t("share.addstep.line_done"),
      AddStepLine.nothing => t("share.blocked.line$sign"),
    };
    final names = next.names(plan).join(" + ");
    final label = switch (next.kind) {
      NextKind.add => t("share.addstep.add", {"name": names}),
      NextKind.addAgain => t("share.addstep.add_again", {"name": names}),
      NextKind.fetchAgain => t("share.addstep.fetch_again", {"name": names}),
      NextKind.choose => t("share.addstep.choose"),
      NextKind.review => t("share.addstep.review$sign"),
      NextKind.close => t("share.button.close"),
    };
    void go() => switch (next.kind) {
      NextKind.review => onReview(),
      NextKind.close => onClose(),
      NextKind.choose => onAdd(next.choice!, null),
      _ => onAdd(next.choice!, next.way),
    };

    final wrong = plan.wrongCredentialIssued;
    final trust = RequestorTrustStyle.of(context, session.requestor);
    final kind = signing
        ? "sign"
        : (session.offeredCredentials ?? const []).isNotEmpty
        ? "share_receive"
        : "share";
    void openTrust() => showRequestorTrustSheet(
      context: context,
      requestor: session.requestor,
      logoHeroTag: requestorLogoHeroTag(session.requestor),
      onDontShare: onClose,
      technicalDetails: technicalDetailsOf(session, const [], t),
    );

    final bar = ActionBar(
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            _Progress(
              parts: header.line == AddStepLine.nothing ? 0 : rows.length,
              filled: rows.where((r) => r.state == AddRowState.done).length,
              line: line,
            ),
            KeyedSubtree(
              key: next.kind == NextKind.review
                  ? DisclosureKeys.button
                  : DisclosureKeys.next,
              child: PrimaryPillButton(label: label, onPressed: go),
            ),
          ],
        ),
      ],
    );

    return SessionScaffold(
      appBarTitle: "share.bar.$kind",
      onDismiss: onDismiss,
      scrollsUnderBars: true,
      bottomNavigationBar: bar,
      startBar: RequestorCompactBar(
        requestor: session.requestor,
        subtitle: [
          t("share.ask.$kind"),
          if (trust.label case final l?) inSentenceOf(context, l),
        ].join(" · "),
        onInfo: openTrust,
      ),
      body: Builder(
        builder: (context) {
          final insets = BarInsets.of(context);
          return FillScrollView(
            key: DisclosureKeys.addStep,
            scrollKey: DisclosureKeys.scrollView,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16 + insets.left,
              16 + insets.top,
              16 + insets.right,
              16 + insets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    key: DisclosureKeys.title,
                    style: palette
                        .display(24, weight: FontWeight.w700)
                        .copyWith(height: 30 / 24, color: palette.heading),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    lead,
                    style: palette
                        .body(15)
                        .copyWith(height: 21 / 15, color: palette.text),
                  ),
                ),
                const SizedBox(height: 22),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (n, row) in rows.indexed)
                        _AddRow(
                          key: Key(
                            row.state == AddRowState.done
                                ? "add_step_done_${row.choice}"
                                : "add_step_row_${row.choice}",
                          ),
                          plan: plan,
                          row: row,
                          line: n > 0,
                          requestor: requestor,
                          landingKey: landingKey(row.choice),
                          onTap: !row.todo
                              ? null
                              : () => onAdd(
                                  row.choice,
                                  row.ways.length == 1 ? row.ways.single : null,
                                ),
                        ),
                    ],
                  ),
                ),
                if (header.otherValueHelp)
                  _Help(
                    key: DisclosureKeys.addStepHelp,
                    text: t("share.addstep.other_help$sign"),
                  ),
                if (wrong != null)
                  _Help(
                    key: DisclosureKeys.addStepWrongKind,
                    text: t("share.offer.wrong_kind", {
                      "name": wrong.name,
                      "requestor": requestor,
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One row of the add step.
class _AddRow extends StatelessWidget {
  final DisclosurePlan plan;
  final AddStepRow row;
  final bool line;
  final String requestor;
  final GlobalKey landingKey;
  final VoidCallback? onTap;

  const _AddRow({
    super.key,
    required this.plan,
    required this.row,
    required this.line,
    required this.requestor,
    required this.landingKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final choice = plan.choices[row.choice];
    String orList(List<String> xs) => joinOr(context, xs);
    String name(DisclosureSlot s) => addableFor(s)?.name ?? slotName(s);

    // The pictures, title, and the line under it per state.
    final List<Widget> arts;
    final String title;
    String? sub;
    var subTone = _Tone.plain;
    final extra = <String>[];
    switch (row.state) {
      case AddRowState.done:
        final option = choice.options[row.doneOption!];
        arts = [
          for (final s in option.slots)
            if (s.candidates.firstWhereOrNull(usable) case final c?)
              _OwnedArt(card: c),
        ];
        title = [for (final s in option.slots) slotName(s)].join(" + ");
        sub = t("share.addstep.added");
        subTone = _Tone.ok;
      case AddRowState.blocked:
        final slot = row.blockedSlot;
        final d = slot == null ? null : addableFor(slot);
        arts = [if (d != null) _TypeArt(descriptor: d)];
        title = slot == null ? "" : name(slot);
        final issuer = d?.issuer.name ?? "";
        sub = row.problem != null
            ? t("share.blocked.cant_renew", {
                "problem": problemWord(context, row.problem!),
                "issuer": issuer,
              })
            : issuer.isEmpty
            ? t("share.blocked.cant_add_unknown")
            : t("share.blocked.cant_add", {"issuer": issuer});
        subTone = _Tone.bad;
      case AddRowState.oneWay:
        final way = row.ways.single;
        final option = choice.options[way.option];
        arts = [
          for (final s in option.slots)
            if (way.todo.contains(s))
              if (addableFor(s) case final d?)
                _TypeArt(descriptor: d)
              else
                _Blank()
            else if (s.candidates.firstWhereOrNull(usable) case final c?)
              _OwnedArt(card: c),
        ];
        title = [for (final s in option.slots) name(s)].join(" + ");
        if (row.otherValue case final o?) {
          sub = t("share.addstep.in_app", {
            "name": o.have.effectiveDisplayName,
            "value": localizedAttributeText(context, o.have.value) ?? "",
          });
          subTone = _Tone.bad;
          extra.add(askedText(context, o.asked));
        } else if (row.problem case final p?) {
          sub = t("share.problem.add_again", {
            "problem": problemWord(context, p),
          });
          subTone = _Tone.bad;
        } else if (row.together case (final have, final total)) {
          sub = t("share.addstep.together", {
            "have": "$have",
            "total": "$total",
          });
        } else {
          sub = addableFor(way.todo.first)?.issuer.name;
        }
      case AddRowState.severalCards:
        arts = [
          for (final w in row.ways.take(3))
            if (addableFor(w.todo.first) case final d?) _TypeArt(descriptor: d),
        ];
        title = orList([for (final w in row.ways) name(w.todo.first)]);
        if (row.problemWay case final w?) {
          sub = t("share.problem.one_of_bad", {
            "name": name(w.todo.first),
            "problem": inSentenceOf(context, problemWord(context, w.problem!)),
          });
          subTone = _Tone.bad;
        } else if (row.otherValue case final o?) {
          sub = t("share.addstep.in_app", {
            "name": o.have.effectiveDisplayName,
            "value": localizedAttributeText(context, o.have.value) ?? "",
          });
          subTone = _Tone.bad;
          extra.add(askedText(context, o.asked));
        } else {
          sub = t("share.addstep.one_enough");
        }
      case AddRowState.severalThings:
        arts = [
          for (final w in row.ways.take(3))
            if (addableFor(w.todo.first) case final d?) _TypeArt(descriptor: d),
        ];
        title = t("share.addstep.ways", {
          "count": countWord(context, row.ways.length),
        });
        sub = [
          for (final w in row.ways)
            [
              for (final s in choice.options[w.option].slots) name(s),
            ].join(" + "),
        ].join(" · ");
    }
    if (row.otherValue == null) {
      for (final a in row.asked) {
        extra.add(askedText(context, a));
      }
    }

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Container(
        decoration: line
            ? BoxDecoration(
                border: Border(top: BorderSide(color: palette.divider)),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          spacing: 14,
          children: [
            FlightSpot(
              flightKey: landingKey,
              child: _Fan(arts: arts, plus: row.todo),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: palette
                        .display(15, weight: FontWeight.w600)
                        .copyWith(height: 20 / 15, color: palette.text),
                  ),
                  if (sub != null && sub.isNotEmpty)
                    Text(
                      sub,
                      style: palette
                          .body(
                            13,
                            weight: subTone == _Tone.plain
                                ? FontWeight.w400
                                : FontWeight.w600,
                          )
                          .copyWith(
                            height: 18 / 13,
                            color: switch (subTone) {
                              _Tone.plain => palette.secondaryText,
                              _Tone.ok => palette.successText,
                              _Tone.bad => palette.errorText,
                            },
                          ),
                    ),
                  for (final e in extra)
                    if (e.isNotEmpty) AskedTagChip(text: e),
                ],
              ),
            ),
            if (row.state == AddRowState.done)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: palette.successText,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: palette.surface,
                ),
              )
            else if (row.todo)
              Icon(Icons.chevron_right_rounded, size: 22, color: palette.faint),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

enum _Tone { plain, ok, bad }

/// The blue tag of what is asked of a value.
class AskedTagChip extends StatelessWidget {
  final String text;
  const AskedTagChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("add_step_asked"),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: palette.infoSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: palette
            .body(12.5, weight: FontWeight.w600)
            .copyWith(height: 18 / 12.5, color: palette.link),
      ),
    );
  }
}

class _Help extends StatelessWidget {
  final String text;
  const _Help({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
      child: Text(
        text,
        style: palette
            .body(14.5)
            .copyWith(height: 21 / 14.5, color: palette.text),
      ),
    );
  }
}

/// A card to add: its type's picture, faded.
class _TypeArt extends StatelessWidget {
  final CredentialDescriptor descriptor;
  const _TypeArt({required this.descriptor});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.45,
    child: CredentialTypeThumbnail(descriptor: descriptor, width: 58),
  );
}

/// A card in the app: its picture, solid.
class _OwnedArt extends ConsumerWidget {
  final SelectableCredentialInstance card;
  const _OwnedArt({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CredentialCardArt(
    credential: sharedCardFor(card, ref.watch(walletCardsProvider)),
    width: 58,
  );
}

class _Blank extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 58, height: 37);
}

/// Up to three pictures, fanned, with a plus badge for a row to do.
class _Fan extends StatelessWidget {
  final List<Widget> arts;
  final bool plus;
  const _Fan({required this.arts, required this.plus});

  static const _turns = [
    [0.0],
    [-7.0, 7.0],
    [-7.0, 0.0, 7.0],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shown = arts.take(3).toList();
    final turns = shown.isEmpty ? const <double>[] : _turns[shown.length - 1];
    return SizedBox(
      width: 66,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, art) in shown.indexed)
            Positioned(
              left: i * 4.0,
              top: 4 + i.toDouble(),
              child: Transform.rotate(
                angle: turns[i] * 3.14159265 / 180,
                child: art,
              ),
            ),
          if (plus)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, size: 16, color: palette.link),
              ),
            ),
        ],
      ),
    );
  }
}

/// The progress of the add step: a part per row, filled by how many are
/// done, and the line beside them.
class _Progress extends StatelessWidget {
  final int parts;
  final int filled;
  final String line;
  const _Progress({
    required this.parts,
    required this.filled,
    required this.line,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: line,
    excludeSemantics: true,
    liveRegion: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        if (parts > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (var i = 0; i < parts; i++)
                ProgressPart(width: 28, filled: i < filled),
            ],
          ),
        Flexible(
          child: Text(
            line,
            key: DisclosureKeys.addStepLine,
            textAlign: parts > 0 ? TextAlign.start : TextAlign.center,
            style: ProgressPart.lineStyle(context),
          ),
        ),
      ],
    ),
  );
}
