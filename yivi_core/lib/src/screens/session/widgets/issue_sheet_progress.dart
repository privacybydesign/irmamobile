import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/irma_avatar.dart";
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

/// Where adding a card stands, under the bar of the sheet it is added in:
/// a tag ([subject]): "For {requestor}", so it is clear the card is for the
/// request behind the sheet, or the card itself when there is no request;
/// then three segments (1 the card's details, 2 proving it, 3 adding it)
/// and "1 of 3". The segments fill blue up to the step; once the card is
/// added ([done]) all three are green and it says "Done".
///
/// Each step of the sheet has a progress of its own, so the bar remembers
/// where it stood ([GlassSheetPages.memoryOf]) and fills (or empties) on from
/// there: it moves smoothly from step to step.
class IssueSheetProgress extends StatefulWidget {
  final IssueSheetSubject subject;

  /// 1, 2 or 3: the step on screen. The ones up to it are filled.
  final int step;
  final bool done;

  static const int total = 3;

  const IssueSheetProgress({
    super.key,
    required this.subject,
    required this.step,
    this.done = false,
  }) : assert(step >= 1 && step <= total);

  @override
  State<IssueSheetProgress> createState() => _IssueSheetProgressState();
}

/// Where a bar stood: how far it was filled, and whether it was green.
typedef _Shown = ({double fill, bool done});

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

  /// Where the bar moves from; it is at [_to] when [_move] is done.
  _Shown _from = (fill: 0, done: false);
  bool _started = false;

  _Shown get _to => (
    fill: (widget.done ? IssueSheetProgress.total : widget.step).toDouble(),
    done: widget.done,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // From where the previous step's bar stood; a first bar fills from empty.
    final last = GlassSheetPages.memoryOf(context)?[_memoryKey];
    _go(from: last is _Shown ? last : (fill: 0, done: false));
  }

  @override
  void didUpdateWidget(IssueSheetProgress old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step || old.done != widget.done) {
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
  _Shown get _now {
    final t = _curve.value;
    final to = _to;
    return (
      fill: _from.fill + (to.fill - _from.fill) * t,
      done: t < 0.5 ? _from.done : to.done,
    );
  }

  void _go({required _Shown from}) {
    _from = from;
    // The page on top tells the next one where it ends up; the one under it
    // (shown only while pages change) does not.
    if (GlassSheetPages.isTopPage(context)) {
      GlassSheetPages.memoryOf(context)?[_memoryKey] = _to;
    }
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final still = reduce || (from.fill == _to.fill && from.done == _to.done);
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
    final params = {"step": "$step", "total": "${IssueSheetProgress.total}"};
    final track = palette.link.withValues(alpha: 0.15);

    return Row(
      spacing: 10,
      children: [
        switch (widget.subject) {
          _ForRequest(:final requestor) => _Tag(
            key: const Key("issue_sheet_progress_tag"),
            avatar: SessionRequestorHeader.avatarOf(requestor, size: 20),
            label: t("share.sheet.for_requestor", {
              "requestor": requestor.name,
            }),
          ),
          _ForCard(:final card) => _Tag(
            key: const Key("issue_sheet_progress_tag"),
            avatar: IrmaAvatar(
              size: 20,
              initials: card.name.isEmpty ? null : card.name.characters.first,
              logoImage: card.image == null
                  ? null
                  : Base64Image(
                      base64: card.image!.base64,
                      mimeType: card.image!.mimeType,
                    ),
            ),
            label: card.name,
          ),
        },
        Expanded(
          // Read out when the step changes.
          child: Semantics(
            liveRegion: true,
            label: done
                ? t("share.sheet.progress_done_label")
                : t("share.step_count", params),
            excludeSemantics: true,
            child: Row(
              spacing: 5,
              children: [
                for (var i = 1; i <= IssueSheetProgress.total; i++)
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _curve,
                      builder: (context, _) {
                        final now = _now;
                        // Blue while adding, green once added; the colour
                        // follows the fill when it turns.
                        final fromInk = _from.done
                            ? palette.successText
                            : palette.link;
                        final toInk = done ? palette.successText : palette.link;
                        final ink = Color.lerp(fromInk, toInk, _curve.value)!;
                        final part = (now.fill - (i - 1)).clamp(0.0, 1.0);
                        return Container(
                          key: Key("issue_sheet_progress_$i"),
                          height: 5,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: track,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: part,
                              heightFactor: 1,
                              child: ColoredBox(color: ink),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: ExcludeSemantics(
                    child: Text(
                      done
                          ? t("share.sheet.progress_done")
                          : t("share.sheet.progress_short", params),
                      key: const Key("issue_sheet_progress_text"),
                      style: palette
                          .body(12.5)
                          .copyWith(color: palette.secondaryText),
                    ),
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

/// The pill with a logo (or initial) and its label.
class _Tag extends StatelessWidget {
  final Widget avatar;
  final String label;

  const _Tag({super.key, required this.avatar, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ConstrainedBox(
      // A long name gives way to the steps.
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        height: 28,
        padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 12, 0),
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: StadiumBorder(side: BorderSide(color: palette.outline)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ExcludeSemantics(child: avatar),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette
                    .body(12, weight: FontWeight.w600)
                    .copyWith(color: palette.heading),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
