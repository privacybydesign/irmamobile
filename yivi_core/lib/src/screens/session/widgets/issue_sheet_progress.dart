import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
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
/// and "1 of 3". Once the card is added ([done]) all three are green and it
/// says "Done".
class IssueSheetProgress extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    final params = {"step": "$step", "total": "$total"};
    final filled = done ? total : step;
    final fill = done ? palette.successText : palette.primary;

    return Row(
      spacing: 10,
      children: [
        switch (subject) {
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
                for (var i = 1; i <= total; i++)
                  Expanded(
                    child: AnimatedContainer(
                      key: Key("issue_sheet_progress_$i"),
                      duration: const Duration(milliseconds: 300),
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i <= filled
                            ? fill
                            : palette.link.withValues(alpha: 0.15),
                      ),
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
