import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/step_number_disc.dart";
import "../../../widgets/surface_card.dart";

/// The step of adding a card that sends you to the issuer's website, as a
/// page of the sheet: the Yivi app and the browser with an arrow there and
/// back (no drawn website: the real one looks different), "Continue on the
/// website", what happens, three numbered steps (your browser opens {host},
/// you do there what {issuer} asks, Yivi opens again by itself), and the
/// way on, "To {host}" ([onOpen]). Back with nothing received ([opened]):
/// "Not done on the website yet?" with an hourglass on the browser,
/// "Continue on the website", and "Choose something else" ([onOther]).
///
/// Also the OpenID4VCI step that asks the issuer's login in the browser.
class IssueWebsiteStep extends StatefulWidget {
  /// The page's name (read out; the bar shows it once the heading has
  /// scrolled away).
  final String title;

  /// The website's address, under the browser.
  final String host;

  /// Who issues the card.
  final String issuer;

  final bool opened;
  final Future<void> Function() onOpen;
  final VoidCallback onBack;

  /// Above the way on (the progress of adding a card).
  final Widget? bottom;

  /// In the middle of the bar (who the card is for).
  final Widget? titleWidget;

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
    this.bottom,
    this.titleWidget,
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
    final align = sideways ? TextAlign.start : TextAlign.center;

    final heading = Semantics(
      header: true,
      child: Text(
        context.tr(
          opened ? "data.add.website.not_done" : "data.add.website.heading",
          params,
        ),
        key: const Key("sheet_website_heading"),
        textAlign: align,
        style: palette
            .display(22, weight: FontWeight.w700)
            .copyWith(height: 30 / 22, color: palette.heading),
      ),
    );
    final lead = Text(
      context.tr(
        opened ? "data.add.website.not_done_body" : "data.add.website.lead",
        params,
      ),
      textAlign: align,
      style: palette.body(15).copyWith(height: 22 / 15, color: palette.heading),
    );
    final steps = opened
        ? null
        : SurfaceCard(
            key: const Key("sheet_website_steps"),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final (n, key) in const [
                  "data.add.website.step_open",
                  "data.add.website.step_do",
                  "data.add.website.step_back",
                ].indexed)
                  _NumberedStep(n: n + 1, text: context.tr(key, params)),
              ],
            ),
          );
    final other = opened && widget.onOther != null
        ? Center(
            child: TextLink(
              key: const Key("sheet_choose_other"),
              label: context.tr("data.add.website.other"),
              onPressed: widget.onOther,
            ),
          )
        : null;
    final picture = _AppAndBrowser(host: widget.host, waiting: opened);

    return GlassSheetPage(
      title: widget.title,
      titleWidget: widget.titleWidget,
      titleWidgetCentred: true,
      titleAfterScroll: 150,
      onBack: widget.onBack,
      action: SheetAction(
        key: const Key("sheet_open_website"),
        label: opened
            ? context.tr("data.add.website.continue")
            : context.tr("data.add.website.open", params),
        busy: _opening,
        onTap: _open,
      ),
      bottom: widget.bottom,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      split: sideways,
      child: sideways
          // A phone held sideways: the words at the left, the picture and
          // the steps at the right.
          ? SheetSplit(
              start: [heading, lead],
              end: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: picture,
                  ),
                  ?steps,
                  ?other,
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  picture,
                  const SizedBox(height: 28),
                  heading,
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: lead,
                  ),
                  if (steps != null) ...[const SizedBox(height: 24), steps],
                  if (other != null) ...[const SizedBox(height: 16), other],
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
        StepNumberDisc(
          "$n",
          style: palette
              .body(13, weight: FontWeight.w700)
              .copyWith(color: palette.link, height: 1),
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

/// The Yivi app and the browser side by side, an arrow there and one back,
/// with "Yivi" and the website's address under them: Yivi sends you to the
/// website and opens again by itself. While [waiting] (back before the
/// website sent anything) an hourglass sits on the browser.
class _AppAndBrowser extends StatelessWidget {
  final String host;
  final bool waiting;

  const _AppAndBrowser({required this.host, required this.waiting});

  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final label = palette
        .body(13, weight: FontWeight.w600)
        .copyWith(color: palette.heading, height: 18 / 13);
    Widget item(Widget picture, String text, {Key? key}) => SizedBox(
      width: 110,
      child: Column(
        spacing: 10,
        children: [
          picture,
          Text(
            text,
            key: key,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: label,
          ),
        ],
      ),
    );
    Widget arrow(IconData icon) =>
        Icon(icon, size: 26, color: palette.secondaryText);

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          item(
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                yiviAsset("non-free/app_icon.png"),
                width: _size,
                height: _size,
              ),
            ),
            "Yivi",
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Column(
              children: [
                arrow(Icons.arrow_forward_rounded),
                arrow(Icons.arrow_back_rounded),
              ],
            ),
          ),
          item(
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: 38,
                    color: palette.link,
                  ),
                ),
                if (waiting)
                  Positioned(
                    right: -8,
                    bottom: -6,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: palette.infoSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.sheet, width: 3),
                      ),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        size: 15,
                        color: palette.noteText,
                      ),
                    ),
                  ),
              ],
            ),
            host,
            key: const Key("sheet_website_host"),
          ),
        ],
      ),
    );
  }
}
