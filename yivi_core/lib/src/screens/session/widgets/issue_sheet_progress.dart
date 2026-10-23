import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "session_requestor_header.dart";

/// What the tag of an [IssueSheetProgress] names: the request a card is
/// added for ("For {requestor}"), or, with no request behind the sheet, the
/// card being added.
sealed class IssueSheetSubject {
  const IssueSheetSubject();

  const factory IssueSheetSubject.request(TrustedParty requestor) = _ForRequest;
  const factory IssueSheetSubject.card(CredentialDescriptor card) = _ForCard;
}

class _ForRequest extends IssueSheetSubject {
  final TrustedParty requestor;
  const _ForRequest(this.requestor);
}

class _ForCard extends IssueSheetSubject {
  final CredentialDescriptor card;
  const _ForCard(this.card);
}

/// Where adding a card stands, right under the bar of the sheet it is added
/// in: a thin line the full width of the sheet that fills up to the step of
/// the flow ([total]: the details, the steps that prove it, adding it); once
/// the card is added ([done]) it is full. During a request "For {requestor}"
/// goes under it ([subject]), so it is clear the card is for the request
/// behind the sheet.
///
/// Each step of the sheet has a progress of its own, so the bar remembers
/// where it stood ([GlassSheetPages.memoryOf]) and fills (or empties) on from
/// there: it moves smoothly from step to step.
class IssueSheetProgress extends StatefulWidget {
  final IssueSheetSubject subject;

  /// The step on screen, from 1 to [total]. The ones up to it are filled.
  final int step;

  /// How many steps the flow has: 3 for a website, 4 for an e-mail address
  /// or phone number (the address and the code), 5 for a document (6 with a
  /// face check).
  final int total;
  final bool done;

  const IssueSheetProgress({
    super.key,
    required this.subject,
    required this.step,
    this.total = 3,
    this.done = false,
  }) : assert(step >= 1 && step <= total);

  @override
  State<IssueSheetProgress> createState() => _IssueSheetProgressState();
}

/// What a bar leaves for the next one: the part filled, so a flow with
/// another number of steps carries on from the same point.
typedef _Left = ({double part});

class _IssueSheetProgressState extends State<IssueSheetProgress>
    with SingleTickerProviderStateMixin {
  static const _memoryKey = #issueSheetProgress;

  late final _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final _curve = CurvedAnimation(
    parent: _move,
    curve: Curves.easeInOutCubic,
  );

  /// How far (in steps) the bar is filled where it moves from; it is at
  /// [_to] when [_move] is done.
  double _from = 0;
  bool _started = false;

  /// Its page was on top at the last check. Pages stay alive under the next
  /// one, so a page that comes back on top moves its bar from where the
  /// page it covered left it.
  bool _wasTop = true;

  double get _to => (widget.done ? widget.total : widget.step).toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final top = GlassSheetPages.isTopPage(context);
    final backOnTop = top && !_wasTop;
    _wasTop = top;
    if (_started && !backOnTop) return;
    _started = true;
    // From where the previous step's bar stood; a first bar fills from empty.
    final last = GlassSheetPages.memoryOf(context)?[_memoryKey];
    _go(from: last is _Left ? last.part * widget.total : 0);
  }

  @override
  void didUpdateWidget(IssueSheetProgress old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step ||
        old.done != widget.done ||
        old.total != widget.total) {
      _go(from: _now);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _move.dispose();
    super.dispose();
  }

  /// Where the bar is right now.
  double get _now => _from + (_to - _from) * _curve.value;

  void _go({required double from}) {
    _from = from;
    // The page on top tells the next one where it ends up; the one under it
    // (shown only while pages change) does not.
    if (GlassSheetPages.isTopPage(context)) {
      GlassSheetPages.memoryOf(context)?[_memoryKey] = (
        part: _to / widget.total,
      );
    }
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final still = reduce || from == _to;
    if (still) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    final step = widget.step;
    final done = widget.done;
    final params = {"step": "$step", "total": "${widget.total}"};
    final ink = palette.successText;
    final track = palette.text.withValues(alpha: 0.12);

    // One thin line the full width of the sheet, right under the bar, says
    // where you are; the bar's title says what.
    final line = Semantics(
      // The step and the total, for a test to find without a visible count.
      key: ValueKey((
        "issue_sheet_progress",
        done ? widget.total : step,
        widget.total,
      )),
      // Read out when the step changes.
      liveRegion: true,
      label: done
          ? t("share.sheet.progress_done_label")
          : t("share.step_count", params),
      excludeSemantics: true,
      child: Container(
        key: const Key("issue_sheet_progress_line"),
        height: 3,
        color: track,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: (_now / widget.total).clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: ink),
            ),
          ),
        ),
      ),
    );

    // During a request a quiet line under it says who it is for; on a phone
    // held sideways that goes under the bar's title instead
    // ([IssueSheetRequestorLine]).
    return switch (widget.subject) {
      _ForRequest(:final requestor) when !useSheetColumns(context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line,
          Padding(
            key: const Key("issue_sheet_for_requestor"),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Row(
              spacing: 8,
              children: [
                ExcludeSemantics(child: requestorAvatar(requestor, size: 20)),
                Flexible(
                  child: Text(
                    t("share.sheet.for_requestor", {
                      "requestor": requestor.name,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .body(13)
                        .copyWith(color: palette.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      _ => line,
    };
  }
}

/// Who a card is added for, centred under the title in the bar of the
/// sheet, on a phone held sideways (elsewhere [IssueSheetProgress] shows it
/// under its line): the requestor's avatar and "For {requestor}". Nothing when the
/// card is not added for a request.
class IssueSheetRequestorLine extends StatelessWidget {
  final IssueSheetSubject subject;

  const IssueSheetRequestorLine({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final subject = this.subject;
    if (subject is! _ForRequest || !useSheetColumns(context)) {
      return const SizedBox.shrink();
    }
    final palette = YiviPalette.of(context);
    return Row(
      key: const Key("issue_sheet_for_requestor"),
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        ExcludeSemantics(child: requestorAvatar(subject.requestor, size: 16)),
        Flexible(
          child: Text(
            FlutterI18n.translate(
              context,
              "share.sheet.for_requestor",
              translationParams: {"requestor": subject.requestor.name},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette
                .body(12)
                .copyWith(color: palette.secondaryText, height: 16 / 12),
          ),
        ),
      ],
    );
  }
}
