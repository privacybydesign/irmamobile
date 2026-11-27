import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../models/disclosure_plan_view.dart";
import "add_first_page.dart";
import "add_picker_page.dart";
import "card_spots.dart";
import "disclosure_change_page.dart";
import "disclosure_overview_page.dart";
import "which_card_sheet.dart";
import "which_combination_sheet.dart";

/// The disclosure (and signature) request of [session], in phases on one
/// route: first "Eerst toevoegen" when a required choice could not be
/// answered when it opened (or the request cannot be finished at all), then
/// the overview. The phases change with a shared-axis page change.
class DisclosureFlow extends ConsumerStatefulWidget {
  final SessionState session;
  final VoidCallback onDismiss;

  /// Ends the session without asking.
  final VoidCallback onClose;

  /// Shares [choices]; [shared] are the cards that go, for the done screen.
  final void Function(
    List<ChoiceSelection> choices,
    List<SelectableCredentialInstance> shared,
  )
  onShare;

  const DisclosureFlow({
    super.key,
    required this.session,
    required this.onDismiss,
    required this.onClose,
    required this.onShare,
  });

  @override
  ConsumerState<DisclosureFlow> createState() => _DisclosureFlowState();
}

enum _Phase { add, overview, change }

class _DisclosureFlowState extends ConsumerState<DisclosureFlow> {
  /// "Bekijk wat je deelt" was tapped: the add step is done with.
  bool _reviewed = false;

  /// "Kies wat je deelt" is open, brought to [_changeTo] when set.
  bool _changing = false;
  int? _changeTo;

  final _spots = CardSpots();

  /// Changes the page with [change], carrying the cards drawn on [from] to
  /// their places on [to] (2.8).
  void _carry(String from, String to, VoidCallback change) {
    final boxes = _spots.boxes(context, from);
    setState(change);
    _spots.carry(
      context,
      from: boxes,
      page: to,
      card: (h) => candidateOf(widget.session.disclosurePlan, h),
      wallet: ref.read(walletCardsProvider),
    );
  }

  void _openChange(int? choice) => _carry("overview", "change", () {
    _changing = true;
    _changeTo = choice;
  });

  /// A sheet over the change page closed: the cards in it go back to their
  /// places there ([boxes] taken as it went).
  void _sheetLeft(Map<String, Rect> boxes) => _spots.carry(
    context,
    from: boxes,
    page: "change",
    card: (h) => candidateOf(widget.session.disclosurePlan, h),
    wallet: ref.read(walletCardsProvider),
  );

  /// Opens a sheet over the change page: the cards of [choice] in use fly
  /// from their heads into it.
  void _intoSheet(int choice) {
    final plan = widget.session.disclosurePlan;
    if (plan == null) return;
    final chosen = resolve(
      plan,
      ref.read(disclosureSelectionProvider(_id)),
      sharesOf: ref.read(sharesOfProvider(_id)),
    );
    final hashes = {
      for (final s
          in chosen.optionOf(choice)?.slots ?? const <DisclosureSlot>[])
        for (final c in chosen.of(s)) c.hash,
    };
    final boxes = {
      for (final MapEntry(:key, :value)
          in _spots.boxes(context, "change").entries)
        if (hashes.contains(key)) key: value,
    };
    _spots.carry(
      context,
      from: boxes,
      page: "sheet",
      card: (h) => candidateOf(plan, h),
      wallet: ref.read(walletCardsProvider),
    );
  }

  /// The sheets of the change page (2.5).
  late final _actions = ChangeActions(
    pickCard: (i) {
      _intoSheet(i);
      showWhichCardSheet(
        context: context,
        sessionId: _id,
        choice: i,
        onAdd: _addFromSheet,
        spots: _spots,
        onLeave: _sheetLeft,
      );
    },
    pickSlot: (i, slot) {
      _intoSheet(i);
      showWhichCardSheet(
        context: context,
        sessionId: _id,
        choice: i,
        slot: slot,
        onAdd: _addFromSheet,
        spots: _spots,
        onLeave: _sheetLeft,
      );
    },
    pickCombination: (i) {
      _intoSheet(i);
      showWhichCombinationSheet(
        context: context,
        sessionId: _id,
        choice: i,
        onAdd: _add,
        spots: _spots,
        onLeave: _sheetLeft,
      );
    },
    add: _add,
  );

  /// The phase shown, and whether the last change went deeper (add step →
  /// overview → change page) or back.
  _Phase? _phase;
  bool _forward = true;

  final _landing = <int, GlobalKey>{};

  GlobalKey _landingKey(int choice) =>
      _landing[choice] ??= GlobalKey(debugLabel: "add_row_$choice");

  int get _id => widget.session.id;

  /// Adds for [choice]: straight on [way], else from "Kies wat je
  /// toevoegt" with [ways] (by default the ways to complete it).
  void _add(int choice, AddWay? way, {List<AddWay>? ways}) {
    final plan = widget.session.disclosurePlan;
    if (plan == null || choice >= plan.choices.length) return;
    showAddSheet(
      context: context,
      sessionId: _id,
      choice: choice,
      ways: ways ?? addWays(plan.choices[choice]),
      way: way,
      landing: _landingKey(choice),
      liftFrom: way == null ? null : _landingKey(choice),
    );
  }

  /// "＋ Ander … toevoegen" in "Welk kaartje deel je?": a card of a kind in
  /// the sheet, also one already in the app (not a singleton: irmago leaves
  /// that out).
  void _addFromSheet(int choice, List<AddWay> ways) =>
      _add(choice, ways.length == 1 ? ways.single : null, ways: ways);

  @override
  Widget build(BuildContext context) {
    final plan =
        widget.session.disclosurePlan ?? DisclosurePlan(choices: const []);
    final fixed = ref.watch(fixedChoicesProvider(_id)) ?? const <int>[];
    final blocked = blockedChoices(plan).isNotEmpty;
    final phase = !_reviewed && (fixed.isNotEmpty || blocked)
        ? _Phase.add
        : _changing
        ? _Phase.change
        : _Phase.overview;
    if (phase != _phase) {
      _forward = phase.index > (_phase?.index ?? -1);
      _phase = phase;
    }
    final page = switch (phase) {
      _Phase.add => AddFirstPage(
        key: const ValueKey(_Phase.add),
        session: widget.session,
        fixed: fixed,
        onDismiss: widget.onDismiss,
        onClose: widget.onClose,
        onReview: () => _carry("add", "overview", () => _reviewed = true),
        onAdd: _add,
        landingKey: _landingKey,
        spots: _spots,
      ),
      _Phase.overview => DisclosureOverviewPage(
        key: const ValueKey(_Phase.overview),
        session: widget.session,
        onDismiss: widget.onDismiss,
        onClose: widget.onClose,
        onShare: widget.onShare,
        onChange: _openChange,
        spots: _spots,
      ),
      _Phase.change => DisclosureChangePage(
        key: const ValueKey(_Phase.change),
        session: widget.session,
        actions: _actions,
        scrollTo: _changeTo,
        spots: _spots,
        onDone: () => _carry("change", "overview", () => _changing = false),
      ),
    };
    return AnimatedSwitcher(
      duration: YiviMotion.duration(context, const Duration(milliseconds: 380)),
      transitionBuilder: (child, animation) =>
          _SharedAxis(animation: animation, forward: _forward, child: child),
      layoutBuilder: (current, previous) =>
          Stack(children: [...previous, ?current]),
      child: page,
    );
  }
}

/// The app's shared-axis page change: the new page comes in from 30 pt to
/// the side while fading in; the old one goes the other way, fading out.
class _SharedAxis extends StatelessWidget {
  final Animation<double> animation;
  final bool forward;
  final Widget child;

  const _SharedAxis({
    required this.animation,
    required this.forward,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final t = YiviMotion.ease.transform(animation.value);
      final status = animation.status;
      final leaving =
          status == AnimationStatus.reverse ||
          status == AnimationStatus.dismissed;
      final side = (forward ? 1 : -1) * (leaving ? -1 : 1);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(30.0 * (1 - t) * side, 0),
          child: child,
        ),
      );
    },
  );
}
