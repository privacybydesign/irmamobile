import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../../widgets/sheet/sheet_heading.dart";
import "../issuance/issue_sheet_progress.dart";
import "../issue_flow/issue_flow_controller.dart";
import "../issue_flow/issue_sheet.dart";
import "../models/disclosure_plan_view.dart";
import "../models/issuance_view_model.dart";
import "disclosure_keys.dart";
import "disclosure_words.dart";

/// Adds cards for choice [choice] of request [sessionId] in one sheet (2.5.3,
/// 2.5.4): straight on [way] when there is one way, else first "Kies wat je
/// toevoegt" with [ways]. A way of several cards adds them one after the
/// other ("kaartje 1 van 2"). The added card flies to [landing] as the sheet
/// goes.
Future<void> showAddSheet({
  required BuildContext context,
  required int sessionId,
  required int choice,
  required List<AddWay> ways,
  AddWay? way,
  GlobalKey? landing,
  GlobalKey? liftFrom,
}) => showSheet<void>(
  context: context,
  motion: way != null ? SheetMotion.issue : SheetMotion.share,
  builder: (_) => AddSheet(
    key: const Key("add_sheet"),
    sessionId: sessionId,
    choice: choice,
    ways: ways,
    way: way,
    landing: landing,
    liftFrom: liftFrom,
  ),
);

class AddSheet extends ConsumerStatefulWidget {
  final int sessionId;
  final int choice;
  final List<AddWay> ways;
  final AddWay? way;
  final GlobalKey? landing;

  /// The picture the sheet opened from (a row of the add step): it rises
  /// into the first page's picture.
  final GlobalKey? liftFrom;

  const AddSheet({
    super.key,
    required this.sessionId,
    required this.choice,
    required this.ways,
    this.way,
    this.landing,
    this.liftFrom,
  });

  @override
  ConsumerState<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<AddSheet> {
  late final _config = IssueFlowConfig(
    requestId: widget.sessionId,
    start: widget.way == null ? null : _descriptors(widget.way!).firstOrNull,
  );
  final _keys = IssueSheetKeys();
  final _title = GlobalKey(debugLabel: "add_picker_title");

  /// The cards of the way being added, in order.
  late List<CredentialDescriptor> _queue = widget.way == null
      ? const []
      : _descriptors(widget.way!);

  IssueFlowController get _flow =>
      ref.read(issueFlowProvider(_config).notifier);

  SessionState? get _request =>
      ref.read(sessionStateProvider(widget.sessionId)).value;

  String get _requestor => _request?.requestor.name ?? "";

  bool get _signing => _request?.type == SessionType.signature;

  static List<CredentialDescriptor> _descriptors(AddWay way) => [
    for (final s in way.todo) ?addableFor(s),
  ];

  @override
  void initState() {
    super.initState();
    final from = widget.liftFrom;
    final d = _queue.firstOrNull;
    if (from != null && d != null) _rise(from, d);
  }

  /// Per way, where its pictures are in the picker.
  final _wayKeys = <int, GlobalKey>{};

  GlobalKey _wayKey(int option) =>
      _wayKeys[option] ??= GlobalKey(debugLabel: "add_way_$option");

  void _pick(AddWay way) {
    setState(() => _queue = _descriptors(way));
    if (_queue.isEmpty) return;
    _flow.open(_queue.first);
    _rise(_wayKey(way.option), _queue.first);
  }

  /// The picture at [from] rises into the details' picture of [d] as its
  /// page comes in (2.8).
  void _rise(GlobalKey from, CredentialDescriptor d) {
    Flight.hide([_keys.hero]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flew = Flight.start(
        context,
        from: from,
        to: Flight.boxOf(_keys.hero),
        keys: FlightKey.carry(startOpacity: 0.6),
        duration: const Duration(milliseconds: 620),
        lift: Flight.liftCarried,
        shadow: Flight.shadowCarried,
        radius: const BorderRadius.all(Radius.circular(4)),
        hide: [_keys.hero],
        copy: (context, frame) => SizedBox.fromSize(
          size: frame.size,
          child: FittedBox(
            fit: BoxFit.fill,
            child: CredentialTypeThumbnail(descriptor: d, width: 200),
          ),
        ),
        onLanded: () => Flight.show([_keys.hero]),
      );
      if (!flew) Flight.show([_keys.hero]);
    });
  }

  /// After [added], the card of the way still to add.
  CredentialDescriptor? _nextOf(List<Credential> added) {
    final ids = {for (final c in added) c.credentialId};
    final at = _queue.indexWhere((d) => ids.contains(d.credentialId));
    return at >= 0 && at + 1 < _queue.length ? _queue[at + 1] : null;
  }

  IssueSheetSubject _subject(CredentialDescriptor d) {
    final requestor = _request?.requestor;
    final n = _queue.indexWhere((q) => q.credentialId == d.credentialId);
    return IssueSheetSubject.request(
      requestor ?? d.issuer,
      ofSet: _queue.length > 1 && n >= 0
          ? (n: n + 1, total: _queue.length)
          : null,
    );
  }

  void _beforeAdd(CredentialDescriptor d) {
    final plan = _request?.disclosurePlan;
    if (plan == null || widget.choice >= plan.choices.length) return;
    if (plan.choices[widget.choice].optional) {
      ref
          .read(disclosureSelectionProvider(widget.sessionId).notifier)
          .share(widget.choice, on: true);
    }
  }

  SheetAction _successAction(List<Credential> cards) {
    final next = _nextOf(cards);
    if (next != null) {
      return SheetAction(
        key: const Key("sheet_together_next"),
        label: context.tr("share.sheet.together_add_next", {
          "next": inSentenceAt(context, next.name),
        }),
        onTap: () => setState(() {
          _flow
            ..reset()
            ..open(next);
        }),
      );
    }
    return SheetAction(
      key: const Key("sheet_back_to_request"),
      label: context.tr(
        _signing ? "share.sheet.continue_sign" : "share.sheet.continue_share",
      ),
      onTap: _finish,
    );
  }

  String _successText(List<Credential> cards) {
    final next = _nextOf(cards);
    final params = {
      "name": cards.firstOrNull?.name ?? "",
      "count": "${cards.length}",
      "requestor": _requestor,
    };
    if (next != null) {
      return context.tr("share.sheet.together_added", {
        ...params,
        "next": inSentenceAt(context, next.name),
      });
    }
    final count = _queue.length > 1 ? _queue.length : cards.length;
    return context.tr(
      "share.sheet.added_${count > 1 ? "many" : "one"}${_signing ? "_sign" : ""}",
      {...params, "count": "$count"},
    );
  }

  /// A card added with another value than is asked: the sheet closes at
  /// once and the add step shows what is in the app (2.1).
  bool _onSucceeded(List<Credential> cards) {
    final missing = missingDescriptors(_request?.disclosurePlan);
    if (issuanceMismatches(cards, missing).isEmpty) return false;
    closeIssueSheet(context, ref, _config);
    return true;
  }

  /// "Verder met delen": the new card flies to its row as the sheet goes.
  Future<void> _finish() async {
    final cards = ref.read(issueFlowProvider(_config)).added ?? const [];
    final landing = widget.landing;
    if (landing != null && cards.isNotEmpty) {
      final card = cards.last;
      final flew = Flight.start(
        context,
        from: _keys.added(cards)[cards.length - 1],
        to: Flight.boxOf(landing),
        keys: FlightKey.carry(lift: 0.2, hold: 0.8, startTurn: -0.035),
        duration: const Duration(milliseconds: 950),
        lift: Flight.liftCarried,
        shadow: Flight.shadowCarried,
        radius: const BorderRadius.all(Radius.circular(4)),
        hide: [landing],
        copyKey: const Key("sheet_flight_card"),
        copy: (context, frame) =>
            CredentialCardArt(credential: card, width: frame.size.width),
      );
      if (flew && mounted) {
        Sheet.of(context).delayClose(const Duration(milliseconds: 180));
      }
    }
    if (mounted) closeIssueSheet(context, ref, _config);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(issueFlowProvider(_config));
    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    if (session == null) return const SizedBox.shrink();
    return IssueSheet(
      config: _config,
      keys: _keys,
      host: IssueSheetHost(
        request: session,
        subject: _subject,
        stopText: () =>
            context.tr("share.sheet.stop_text", {"requestor": _requestor}),
        beforeAdd: _beforeAdd,
        successAction: _successAction,
        successLink: (cards) => _nextOf(cards) == null
            ? null
            : (
                key: const Key("sheet_together_later"),
                label: context.tr("share.sheet.later"),
                onTap: () => closeIssueSheet(context, ref, _config),
              ),
        successText: _successText,
        onSucceeded: _onSucceeded,
        hasOtherChoices: widget.ways.length > 1,
      ),
      rootKey: "pick",
      root: flow.direct && flow.adding != null
          ? const SizedBox.shrink()
          : _picker(session),
      rootShift: 0.28,
    );
  }

  Widget _picker(SessionState session) {
    final t = context.tr;
    final palette = YiviPalette.of(context);
    final plan = session.disclosurePlan;
    final choice = plan != null && widget.choice < plan.choices.length
        ? plan.choices[widget.choice]
        : null;
    final title = t("share.addpicker.title");
    return SheetPage.scroll(
      title: SheetTitle(title, reveal: SheetTitleReveal.under(_title)),
      fit: true,
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        0,
        YiviSpace.x16,
        YiviSpace.x24,
      ),
      child: Column(
        key: DisclosureKeys.addPicker,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(
            title: title,
            titleKey: _title,
            lead: t("share.sheet.subtitle_one", {"requestor": _requestor}),
          ),
          const SizedBox(height: YiviSpace.x16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (n, way) in widget.ways.indexed)
                  KeyedSubtree(
                    // For tests: the types this way adds, and the option
                    // (two ways can add the same type).
                    key: Key(
                      "sheet_add_${[for (final d in _descriptors(way)) d.credentialId].join("+")}#${way.option}",
                    ),
                    child: _WayRow(
                      key: DisclosureKeys.addPickerRow(way.option),
                      way: way,
                      names: [
                        for (final s
                            in choice?.options[way.option].slots ?? way.todo)
                          if (way.todo.contains(s))
                            addableFor(s)?.name ?? slotName(s),
                      ],
                      line: n > 0,
                      artKey: _wayKey(way.option),
                      onTap: () => _pick(way),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One way in "Kies wat je toevoegt": the cards it still needs, fanned,
/// their names, who gives them, and a chevron.
class _WayRow extends StatelessWidget {
  final AddWay way;
  final List<String> names;
  final bool line;
  final GlobalKey artKey;
  final VoidCallback onTap;

  const _WayRow({
    super.key,
    required this.way,
    required this.names,
    required this.line,
    required this.artKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final todo = [for (final s in way.todo) ?addableFor(s)];
    final issuers = {for (final d in todo) d.issuer.name}.join(", ");
    final sub = way.owned.isNotEmpty
        ? t("share.addpicker.with_owned", {
            "names": joinAnd(context, [for (final s in way.owned) slotName(s)]),
          })
        : todo.length > 1
        ? t("share.addpicker.cards", {
            "count": countWord(context, todo.length),
            "issuers": issuers,
          })
        : issuers;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: line
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: palette.divider)),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            spacing: 14,
            children: [
              FlightSpot(
                flightKey: artKey,
                child: SizedBox(
                  width: 66,
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (i, d) in todo.take(3).indexed)
                        Positioned(
                          left: i * 6.0,
                          top: 4 + i * 2.0,
                          child: Opacity(
                            opacity: 0.45,
                            child: CredentialTypeThumbnail(
                              descriptor: d,
                              width: 58,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      names.join(" + "),
                      style: palette
                          .display(15, weight: FontWeight.w600)
                          .copyWith(height: 20 / 15, color: palette.text),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: palette
                            .body(13)
                            .copyWith(
                              height: 18 / 13,
                              color: palette.secondaryText,
                            ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: palette.faint),
            ],
          ),
        ),
      ),
    );
  }
}
