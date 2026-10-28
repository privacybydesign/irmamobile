import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/note_box.dart";
import "../../../widgets/surface_card.dart";

/// The step of adding a card that sends you to the issuer's website, as a
/// page of the sheet: three numbered steps (your browser opens {host}, you
/// do there what {issuer} asks, Yivi opens again by itself), a small
/// browser with the website's address, and the way on, "To {host}"
/// ([onOpen]). Back with nothing received ([opened]): "Not done on the
/// website yet?", that the request waits ([requestor]), "Continue on the
/// website", and "Choose something else" ([onOther]).
///
/// Also the OpenID4VCI step that asks the issuer's login in the browser.
class IssueWebsiteStep extends StatefulWidget {
  /// The bar's title.
  final String title;

  /// The website's address, as shown in the small browser.
  final String host;

  /// Who issues the card.
  final String issuer;

  final bool opened;
  final Future<void> Function() onOpen;
  final VoidCallback onBack;

  /// Under the bar, staying put (the progress of adding a card).
  final Widget? pinned;

  /// On a phone held sideways: who the card is for, under the title.
  final Widget? subtitle;

  /// The request that waits meanwhile, if any.
  final String? requestor;

  /// "Choose something else", once back without the card; null when there
  /// is nothing else.
  final VoidCallback? onOther;

  const IssueWebsiteStep({
    super.key,
    required this.title,
    required this.host,
    required this.issuer,
    required this.opened,
    required this.onOpen,
    required this.onBack,
    this.pinned,
    this.subtitle,
    this.requestor,
    this.onOther,
  });

  @override
  State<IssueWebsiteStep> createState() => _IssueWebsiteStepState();
}

class _IssueWebsiteStepState extends State<IssueWebsiteStep> {
  var _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final params = {"issuer": widget.issuer, "host": widget.host};
    final sideways = useSheetColumns(context);

    final opened = widget.opened;
    final words = <Widget>[
      Semantics(
        header: true,
        child: Text(
          context.tr(
            opened ? "data.add.website.not_done" : "data.add.website.heading",
            params,
          ),
          key: const Key("sheet_website_heading"),
          textAlign: TextAlign.center,
          style: palette
              .display(sideways ? 18 : 21, weight: FontWeight.w700)
              .copyWith(height: (sideways ? 24 : 28) / (sideways ? 18 : 21)),
        ),
      ),
      if (opened)
        Text(
          context.tr("data.add.website.not_done_body", params),
          textAlign: TextAlign.center,
          style: palette
              .body(15)
              .copyWith(height: 22 / 15, color: palette.heading),
        )
      else
        Column(
          key: const Key("sheet_website_steps"),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            for (final (n, key) in const [
              "data.add.website.step_open",
              "data.add.website.step_do",
              "data.add.website.step_back",
            ].indexed)
              _NumberedStep(n: n + 1, text: context.tr(key, params)),
          ],
        ),
    ];
    final note = opened && widget.requestor != null
        ? NoteBox(
            key: const Key("sheet_opened_note"),
            text: context.tr("data.add.website.waits", {
              "requestor": widget.requestor!,
            }),
          )
        : null;
    final other = opened && widget.onOther != null
        ? Center(
            child: TextLink(
              key: const Key("sheet_choose_other"),
              label: context.tr("data.add.website.other"),
              onPressed: widget.onOther,
            ),
          )
        : null;
    final picture = opened
        ? null
        : _WebsitePicture(host: widget.host, issuer: widget.issuer);

    return GlassSheetPage(
      title: widget.title,
      onBack: widget.onBack,
      // Left by dragging its header down: no close button.
      closable: false,
      action: SheetAction(
        key: const Key("sheet_open_website"),
        label: widget.opened
            ? context.tr("data.add.website.continue")
            : context.tr("data.add.website.open", params),
        busy: _opening,
        onTap: _open,
      ),
      pinned: widget.pinned,
      subtitle: widget.subtitle,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      split: sideways,
      child: sideways
          // A phone held sideways: the words at the left, the browser at
          // the right.
          ? SheetSplit(
              start: words,
              end: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [?note, ?picture, ?other],
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  ...words,
                  const SizedBox(height: 6),
                  ?note,
                  ?picture,
                  ?other,
                ],
              ),
            ),
    );
  }
}

/// One of the numbered steps of going to the website.
class _NumberedStep extends StatelessWidget {
  final int n;
  final String text;

  const _NumberedStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$n",
              style: palette
                  .body(13, weight: FontWeight.w700)
                  .copyWith(color: palette.link, height: 1),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: palette
                  .body(15)
                  .copyWith(height: 21 / 15, color: palette.heading),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small browser window with the website's address, and under it that
/// it opens in your browser and you come back here.
class _WebsitePicture extends StatelessWidget {
  final String host;
  final String issuer;

  const _WebsitePicture({required this.host, required this.issuer});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget dot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final window = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: palette.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            // One step lighter than the card (the page colour in light).
            color: palette.tint,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              spacing: 5,
              children: [
                dot(const Color(0xFFE0605A)),
                dot(const Color(0xFFE3B341)),
                dot(const Color(0xFF5BBF5B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 16,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: ShapeDecoration(
                      color: palette.surface,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      host,
                      key: const Key("sheet_website_host"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette
                          .body(10.5)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 84,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  issuer,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: palette
                      .display(15)
                      .copyWith(color: palette.secondaryText),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        spacing: 12,
        children: [
          ExcludeSemantics(child: window),
          Text(
            FlutterI18n.translate(context, "data.add.website.caption"),
            textAlign: TextAlign.center,
            style: palette.body(13).copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}
