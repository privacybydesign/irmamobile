import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/surface_card.dart";

/// The step of adding a card that sends you to the issuer's website, as a
/// page of the sheet: what happens there and that you come back by
/// yourself, a small browser with the website's address, and the way on,
/// "Open website" ([onOpen]). Once opened ([opened]) a note says the
/// request waits, and the way on opens it again.
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

    final words = <Widget>[
      Semantics(
        header: true,
        child: Text(
          context.tr("data.add.website.heading", params),
          key: const Key("sheet_website_heading"),
          textAlign: TextAlign.center,
          style: palette
              .display(sideways ? 18 : 21, weight: FontWeight.w700)
              .copyWith(height: (sideways ? 24 : 28) / (sideways ? 18 : 21)),
        ),
      ),
      Text(
        context.tr("data.add.website.body", params),
        textAlign: TextAlign.center,
        style: palette
            .body(15)
            .copyWith(height: 22 / 15, color: palette.heading),
      ),
    ];
    final note = widget.opened
        ? _Note(
            key: const Key("sheet_opened_note"),
            text: context.tr("share.sheet.opened_note", {"host": widget.host}),
          )
        : null;
    final picture = _WebsitePicture(host: widget.host, issuer: widget.issuer);

    return GlassSheetPage(
      title: widget.title,
      onBack: widget.onBack,
      // Left by dragging its header down: no close button.
      closable: false,
      action: SheetAction(
        key: const Key("sheet_open_website"),
        label: widget.opened
            ? context.tr("share.sheet.open_again")
            : context.tr("data.add.website.open"),
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
                children: [?note, picture],
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [...words, const SizedBox(height: 6), ?note, picture],
              ),
            ),
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

/// An explanation in the info colour.
class _Note extends StatelessWidget {
  final String text;

  const _Note({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: palette.infoSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
        ),
      ),
      child: Text(
        text,
        style: palette
            .body(14)
            .copyWith(height: 20 / 14, color: palette.noteText),
      ),
    );
  }
}
