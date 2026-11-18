import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/action_bar.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/numbered_step.dart";
import "../../../widgets/surface_card.dart";
import "session_columns.dart";
import "session_scaffold.dart";

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

  /// The heading, for the bar's title once it has scrolled under the bar.
  final _headingKey = GlobalKey(debugLabel: "website_heading");

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
    final sideways = useSheetColumns(context);
    final parts = _WebsiteParts(
      context,
      host: widget.host,
      issuer: widget.issuer,
      opened: widget.opened,
      sideways: sideways,
      headingKey: _headingKey,
      onOther: widget.onOther,
    );
    final title = SheetTitle(
      widget.title,
      widget: widget.titleWidget,
      centred: true,
      reveal: SheetTitleReveal.under(_headingKey),
    );
    final exits = SheetExits(onBack: widget.onBack);
    final action = SheetAction(
      key: const Key("sheet_open_website"),
      label: parts.openLabel,
      busy: _opening,
      onTap: _open,
    );

    return sideways
        ? GlassSheetPage.split(
            title: title,
            exits: exits,
            action: action,
            bottom: widget.bottom,
            bottomInBar: true,
            // A phone held sideways: the words at the left, the picture and
            // the steps at the right.
            child: SheetSplit(
              start: [parts.heading, parts.lead],
              end: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: YiviSpace.x12,
                children: [
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: YiviSpace.x24,
                    ),
                    child: parts.picture,
                  ),
                  ?parts.steps,
                  ?parts.other,
                ],
              ),
            ),
          )
        : GlassSheetPage.scroll(
            title: title,
            exits: exits,
            action: action,
            bottom: widget.bottom,
            padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
            child: parts.column(),
          );
  }
}

/// The issuer's login for an OpenID4VCI authorization code, full screen:
/// the content of [IssueWebsiteStep] (the app and the browser, "Continue on
/// the website", the three steps) with "To {host}" in the bar. The close at
/// the top declines. Back in the app before the issuer sent anything, it
/// says so ("Not done on the website yet?").
class IssueWebsiteScreen extends StatefulWidget {
  /// The bar's title (a translation key).
  final String titleKey;

  /// The website's address, under the browser.
  final String host;

  /// Who issues the card.
  final String issuer;

  final Future<void> Function() onOpen;
  final VoidCallback onDismiss;

  const IssueWebsiteScreen({
    super.key,
    required this.titleKey,
    required this.host,
    required this.issuer,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  State<IssueWebsiteScreen> createState() => _IssueWebsiteScreenState();
}

class _IssueWebsiteScreenState extends State<IssueWebsiteScreen> {
  var _opening = false;
  var _opened = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _opened = true;
    });
    try {
      await widget.onOpen();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Held sideways, and on a tablet: the words at the left with the button
    // at their foot; the picture and the steps at the right, as the
    // permission screen.
    final columns = SessionLayout.of(context).split;
    final parts = _WebsiteParts(
      context,
      host: widget.host,
      issuer: widget.issuer,
      opened: _opened,
      sideways: columns,
    );
    final onOpen = _opening ? null : _open;
    if (columns) {
      return SessionScaffold(
        wide: true,
        scrollsUnderBars: true,
        cornerClose: true,
        onDismiss: widget.onDismiss,
        // The body's own context sees the bars.
        body: Builder(
          builder: (context) => SidewaysLayout(
            panel: SessionPanel(
              key: const Key("website_panel"),
              top: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: YiviSpace.x12,
                children: [parts.heading, parts.lead],
              ),
              action: FancyPillButton(
                key: const Key("bottom_bar_primary"),
                label: parts.openLabel,
                onPressed: onOpen,
              ),
            ),
            content: SessionPanelContent(
              scrollKey: const Key("website_screen"),
              spacing: YiviSpace.x12,
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: YiviSpace.x24),
                  child: parts.picture,
                ),
                ?parts.steps,
              ],
            ),
          ),
        ),
      );
    }
    return SessionScaffold(
      appBarTitle: widget.titleKey,
      onDismiss: widget.onDismiss,
      bottomNavigationBar: ActionBar.single(
        label: parts.openLabel,
        onTap: onOpen,
      ),
      scrollsUnderBars: true,
      body: BarInsetsBuilder(
        builder: (context, insets) => ListView(
          key: const Key("website_screen"),
          padding:
              insets +
              const EdgeInsets.fromLTRB(
                YiviSpace.x16,
                0,
                YiviSpace.x16,
                YiviSpace.x32,
              ),
          children: [parts.column()],
        ),
      ),
    );
  }
}

/// What the website step says and shows, for a sheet page and full screen.
class _WebsiteParts {
  final Widget heading, lead, picture;
  final Widget? steps, other;
  final String openLabel;

  factory _WebsiteParts(
    BuildContext context, {
    required String host,
    required String issuer,
    required bool opened,
    required bool sideways,
    Key? headingKey,
    VoidCallback? onOther,
  }) {
    final palette = YiviPalette.of(context);
    final params = {"issuer": issuer, "host": host};
    final align = sideways ? TextAlign.start : TextAlign.center;
    return _WebsiteParts._(
      heading: Semantics(
        key: headingKey,
        header: true,
        child: Text(
          context.tr(
            opened ? "data.add.website.not_done" : "data.add.website.heading",
            params,
          ),
          key: const Key("sheet_website_heading"),
          textAlign: align,
          style: palette
              .display(sideways ? 22 : 24, weight: FontWeight.w700)
              .copyWith(
                height: (sideways ? 29 : 30) / (sideways ? 22 : 24),
                color: palette.text,
              ),
        ),
      ),
      lead: Text(
        context.tr(
          opened ? "data.add.website.not_done_body" : "data.add.website.lead",
          params,
        ),
        textAlign: align,
        style: palette
            .body(15)
            .copyWith(height: 22 / 15, color: palette.heading),
      ),
      steps: opened
          ? null
          : SurfaceCard(
              key: const Key("sheet_website_steps"),
              padding: const EdgeInsets.all(YiviSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: YiviSpace.x12,
                children: [
                  for (final (n, key) in const [
                    "data.add.website.step_open",
                    "data.add.website.step_do",
                    "data.add.website.step_back",
                  ].indexed)
                    NumberedStep(
                      number: n + 1,
                      child: Text(context.tr(key, params)),
                    ),
                ],
              ),
            ),
      other: opened && onOther != null
          ? Center(
              child: TextLink(
                key: const Key("sheet_choose_other"),
                label: context.tr("data.add.website.other"),
                onPressed: onOther,
              ),
            )
          : null,
      picture: _AppAndBrowser(host: host, waiting: opened),
      openLabel: opened
          ? context.tr("data.add.website.continue")
          : context.tr("data.add.website.open", params),
    );
  }

  _WebsiteParts._({
    required this.heading,
    required this.lead,
    required this.picture,
    required this.steps,
    required this.other,
    required this.openLabel,
  });

  /// Upright: the picture, the heading and the words, then the steps.
  Widget column() => Padding(
    padding: const EdgeInsets.only(top: YiviSpace.x24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        picture,
        const SizedBox(height: YiviSpace.x32),
        heading,
        const SizedBox(height: YiviSpace.x8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x12),
          child: lead,
        ),
        if (steps case final steps?) ...[
          const SizedBox(height: YiviSpace.x24),
          steps,
        ],
        if (other case final other?) ...[
          const SizedBox(height: YiviSpace.x16),
          other,
        ],
      ],
    ),
  );
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
        spacing: YiviSpace.x12,
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
        spacing: YiviSpace.x16,
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
