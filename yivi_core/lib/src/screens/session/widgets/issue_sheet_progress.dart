import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/press_scale.dart";
import "requestor_card.dart";

/// What a card is added for: the request behind the sheet ("For
/// {requestor}"), or, with no request behind it, nothing.
sealed class IssueSheetSubject {
  const IssueSheetSubject();

  /// For [requestor]'s request; [ofSet] is where the card stands in a set
  /// the request only accepts together (card 1 of 2).
  const factory IssueSheetSubject.request(
    TrustedParty requestor, {
    ({int n, int total})? ofSet,
  }) = _ForRequest;
  const factory IssueSheetSubject.none() = _NoSubject;

  /// The requestor the card is added for, if any.
  TrustedParty? get requestor => null;
}

class _ForRequest extends IssueSheetSubject {
  @override
  final TrustedParty requestor;
  final ({int n, int total})? ofSet;
  const _ForRequest(this.requestor, {this.ofSet});

  /// "For {requestor}", or "For {requestor} · card 1 of 2" in a set.
  String text(BuildContext context) {
    final set = ofSet;
    return FlutterI18n.translate(
      context,
      set == null
          ? "share.sheet.for_requestor"
          : "share.sheet.for_requestor_set",
      translationParams: {
        "requestor": requestor.name,
        if (set != null) "n": "${set.n}",
        if (set != null) "total": "${set.total}",
      },
    );
  }
}

class _NoSubject extends IssueSheetSubject {
  const _NoSubject();
}

/// Where adding a card stands, right above the way on of each of its pages:
/// a short part per step ([total]: the details, the steps that prove it,
/// adding it), filled up to [step], and "Step n of N". It sits in the
/// page's bottom ([GlassSheetPage.bottom]), which stays put while the pages
/// change, so it does not jump; a page without a button keeps the button's
/// room.
class IssueSheetProgress extends StatelessWidget {
  final IssueSheetSubject subject;

  /// The step on screen, from 1 to [total]. The ones up to it are filled.
  final int step;

  /// How many steps the flow has: 3 for a website, 4 for an e-mail address
  /// or phone number (the address and the code), 5 for a document (6 with a
  /// face check).
  final int total;

  const IssueSheetProgress({
    super.key,
    required this.subject,
    required this.step,
    this.total = 3,
  }) : assert(step >= 1 && step <= total);

  /// The progress at the last step, adding the card; none without a
  /// [subject], or for an issuance without steps before it ([total] 0).
  static IssueSheetProgress? lastStep(IssueSheetSubject? subject, int total) =>
      subject == null || total == 0
      ? null
      : IssueSheetProgress(subject: subject, step: total, total: total);

  /// A part's width: narrower for a long flow (a document with a face
  /// check), so it fits a sheet's left column held sideways.
  double get _partWidth => total > 4 ? 18 : 28;
  static const double _partHeight = 4;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final params = {"step": "$step", "total": "$total"};
    final label = context.tr("share.step_count", params);
    return Semantics(
      // The step and the total, for a test to find.
      key: ValueKey(("issue_sheet_progress", step, total)),
      // Read out when the step changes.
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        key: const Key("issue_sheet_progress_parts"),
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (var i = 1; i <= total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _partWidth,
                  height: _partHeight,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? palette.successText
                        : palette.text.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(_partHeight / 2),
                  ),
                ),
            ],
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette
                  .body(12)
                  .copyWith(color: palette.secondaryText, height: 16 / 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the island ([IssueIsland]) of the sheet around it: what the pill
/// in the bar does. Put above the sheet's pages by the flow.
class IssueIslandScope extends InheritedWidget {
  final VoidCallback open;

  /// Whether the island is open (the pill gives way to it).
  final bool isOpen;

  const IssueIslandScope({
    super.key,
    required this.open,
    required this.isOpen,
    required super.child,
  });

  static IssueIslandScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IssueIslandScope>();

  @override
  bool updateShouldNotify(IssueIslandScope old) =>
      old.isOpen != isOpen || old.open != open;
}

/// "For {requestor}" in the middle of the bar of each page of adding a card
/// for a request: the requestor's logo and the words in a light pill with a
/// chevron. A tap grows it into the island, which says why the card is
/// added. Nothing when the card is not added for a request.
class IssueRequestorPill extends StatelessWidget {
  final IssueSheetSubject subject;

  const IssueRequestorPill({super.key, required this.subject});

  /// The pill for [subject]; none without a request.
  static IssueRequestorPill? maybe(IssueSheetSubject? subject) =>
      subject is _ForRequest ? IssueRequestorPill(subject: subject) : null;

  @override
  Widget build(BuildContext context) {
    final subject = this.subject;
    if (subject is! _ForRequest) return const SizedBox.shrink();
    final palette = YiviPalette.of(context);
    final scope = IssueIslandScope.maybeOf(context);
    final text = subject.text(context);
    // While the island is open it stands in the pill's place.
    final pill = AnimatedOpacity(
      opacity: scope?.isOpen ?? false ? 0 : 1,
      duration: const Duration(milliseconds: 150),
      child: Center(
        child: Semantics(
          key: const Key("issue_sheet_for_requestor"),
          button: scope != null,
          label: text,
          hint: scope == null ? null : context.tr("issuance.island.hint"),
          excludeSemantics: true,
          child: PressScale(
            scale: PressScale.glass,
            enabled: scope != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: scope?.open,
              child: Container(
                constraints: const BoxConstraints(minHeight: 34),
                padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 10, 0),
                decoration: ShapeDecoration(
                  color: palette.infoSurface,
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 7,
                  children: [
                    requestorAvatar(subject.requestor, size: 22),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .body(14, weight: FontWeight.w600)
                            .copyWith(color: palette.noteText),
                      ),
                    ),
                    if (scope != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: palette.noteText,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Not squeezed: where the bar leaves it no room (a button in the bar
    // beside it), it gives way.
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < _minWidth ? const SizedBox.shrink() : pill,
    );
  }

  /// Its logo, chevron and a few letters.
  static const double _minWidth = 120;
}
