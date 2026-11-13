// "Hulp nodig?": the one way into support.
//
//   1. What are you running into? The user picks a problem, or the one the
//      app already knows about when they came from an activity or an error.
//   2. The answer: what to do, in a few steps. Solved?
//   3. Only when it is not: who helps further. The problem decides who that
//      is: the organisation that issued or asked for the data, or Yivi
//      support. Yivi only answers for the app and the data it issues itself.

import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/irma_configuration.dart";
import "../../models/log_entry.dart";
import "../../providers/irma_repository_provider.dart";
import "../../sentry/sentry.dart";
import "../../theme/theme.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/chevron.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_divider.dart";
import "../../widgets/link.dart";
import "../../widgets/section_header.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_search_bar.dart";
import "../../widgets/yivi_themed_button.dart";
import "../activity/history_repository.dart";
import "../help/help_screen.dart";
import "../more/widgets/tiles_card.dart";
import "help_problem.dart";
import "recent_organisations.dart";
import "support_party.dart";
import "yivi_support_mail.dart";

const needHelpRouteName = "/need_help";

/// Opens "Hulp nodig?". With [helpContext], what the app already knows is
/// the first option.
Future<void> openNeedHelp(BuildContext context, {HelpContext? helpContext}) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: needHelpRouteName),
        builder: (_) => NeedHelpScreen(helpContext: helpContext),
      ),
    );

/// Closes the whole flow, back to where it was opened.
void _closeFlow(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.popUntil(
    (route) => route.settings.name == needHelpRouteName || route.isFirst,
  );
  if (navigator.canPop()) navigator.pop();
}

String _orgName(BuildContext context, SupportParty? org) =>
    org?.name ?? FlutterI18n.translate(context, "need_help.the_organisation");

String _tr(
  BuildContext context,
  String key, {
  SupportParty? org,
  Map<String, String> params = const {},
}) => FlutterI18n.translate(
  context,
  key,
  translationParams: {"org": _orgName(context, org), ...params},
);

// ─── 1. What are you running into? ────────────────────────────────────────

class NeedHelpScreen extends StatelessWidget {
  final HelpContext? helpContext;

  const NeedHelpScreen({super.key, this.helpContext});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final known = helpContext;

    void open(
      HelpProblem problem, {
      SupportParty? organisation,
      String? errorCode,
    }) {
      // An error report stays with the request, whichever problem the user
      // picks: if it ends at Yivi, the report helps.
      final errorReport = known?.errorReport;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => problem.route == HelpRoute.ask
              ? NeedHelpContactScreen(
                  problem: problem,
                  errorReport: errorReport,
                )
              : NeedHelpAnswerScreen(
                  problem: problem,
                  organisation: organisation,
                  errorCode: errorCode,
                  errorReport: errorReport,
                ),
        ),
      );
    }

    return _HelpScaffold(
      titleKey: "need_help.start.title",
      children: [
        if (known != null) ...[
          SectionHeader(known.sectionKey),
          SizedBox(height: theme.smallSpacing),
          TilesCard(
            children: [
              _HelpRow(
                key: const Key("need_help_context_option"),
                icon: known.problem.icon,
                title: _tr(context, known.labelKey, org: known.organisation),
                subtitle: known.subtitle,
                onTap: () => open(
                  known.problem,
                  organisation: known.organisation,
                  errorCode: known.errorCode,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.mediumSpacing),
        ],
        for (final (headerKey, problems) in HelpProblems.groups) ...[
          SectionHeader(headerKey),
          SizedBox(height: theme.smallSpacing),
          TilesCard(
            children: [
              for (final problem in problems)
                _HelpRow(
                  icon: problem.icon,
                  title: _tr(context, problem.titleKey),
                  subtitle: problem.hasSubtitle
                      ? _tr(context, problem.subtitleKey)
                      : null,
                  onTap: () => open(problem),
                ),
            ],
          ),
          SizedBox(height: theme.mediumSpacing),
        ],
        // Questions about Yivi itself, not a problem: the FAQ.
        const SectionHeader("help.about_irma"),
        SizedBox(height: theme.smallSpacing),
        TilesCard(
          children: [
            _HelpRow(
              key: const Key("need_help_faq_option"),
              icon: Icons.help_outline_rounded,
              title: _tr(context, "more_tab.faq"),
              subtitle: _tr(context, "need_help.start.faq_subtitle"),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => HelpScreen())),
            ),
          ],
        ),
        SizedBox(height: theme.mediumSpacing),
        TilesCard(
          children: [
            _HelpRow(
              icon: HelpProblems.other.icon,
              title: _tr(context, HelpProblems.other.titleKey),
              onTap: () => open(HelpProblems.other),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 2. The answer ────────────────────────────────────────────────────────

class NeedHelpAnswerScreen extends StatelessWidget {
  final HelpProblem problem;
  final SupportParty? organisation;
  final String? errorCode;
  final HelpErrorReport? errorReport;

  const NeedHelpAnswerScreen({
    super.key,
    required this.problem,
    this.organisation,
    this.errorCode,
    this.errorReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final org = organisation;
    String tr(String key) => _tr(context, key, org: org);

    return _HelpScaffold(
      title: tr(problem.titleKey),
      children: [
        if (problem.hasLead) ...[
          _Inset(_Paragraph(tr(problem.leadKey))),
          SizedBox(height: theme.defaultSpacing),
        ],
        if (problem.steps > 0) ...[
          IrmaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < problem.steps; i++) ...[
                  if (i > 0) SizedBox(height: theme.defaultSpacing),
                  _Step(number: i + 1, text: tr(problem.stepKey(i))),
                ],
              ],
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
        ],
        if (problem.hasNote) ...[
          _Inset(_Paragraph(tr(problem.noteKey))),
          SizedBox(height: theme.defaultSpacing),
        ],
        if (errorCode != null) ...[
          _Inset(
            _Paragraph(
              _tr(
                context,
                "need_help.answer.error_code",
                params: {"code": errorCode!},
              ),
              small: true,
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
        ],
        SizedBox(height: theme.smallSpacing),
        _Inset(
          TranslatedText(
            "need_help.answer.question",
            style: theme.boldBody,
            isHeader: true,
          ),
        ),
        SizedBox(height: theme.defaultSpacing),
        YiviThemedButton(
          key: const Key("need_help_solved_button"),
          label: "need_help.answer.solved",
          style: YiviButtonStyle.filled,
          onPressed: () => _closeFlow(context),
        ),
        SizedBox(height: theme.smallSpacing),
        YiviThemedButton(
          key: const Key("need_help_not_solved_button"),
          label: "need_help.answer.not_solved",
          style: YiviButtonStyle.outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NeedHelpContactScreen(
                problem: problem,
                organisation: org,
                errorCode: errorCode,
                errorReport: errorReport,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.tertiary,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$number",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.dark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Who helps you further ─────────────────────────────────────────────

class NeedHelpContactScreen extends StatelessWidget {
  final HelpProblem problem;
  final SupportParty? organisation;
  final String? errorCode;
  final HelpErrorReport? errorReport;

  /// Overrides the problem's route, after the user answered "about what?".
  final HelpRoute? route;

  const NeedHelpContactScreen({
    super.key,
    required this.problem,
    this.organisation,
    this.errorCode,
    this.errorReport,
    this.route,
  });

  HelpRoute get effectiveRoute {
    final r = route ?? problem.route;
    // Yivi's own data and requests: the organisation's support is Yivi's.
    if (r == HelpRoute.organisation && (organisation?.isYivi ?? false)) {
      return HelpRoute.yivi;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return switch (effectiveRoute) {
      HelpRoute.ask => _ContactAsk(this),
      HelpRoute.yivi => _ContactYivi(this),
      HelpRoute.organisation =>
        organisation == null
            ? _ContactChooseOrganisation(this)
            : _ContactOrganisation(this),
    };
  }
}

class _ContactAsk extends StatelessWidget {
  final NeedHelpContactScreen screen;

  const _ContactAsk(this.screen);

  @override
  Widget build(BuildContext context) {
    void go(HelpRoute route) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NeedHelpContactScreen(
          problem: screen.problem,
          errorReport: screen.errorReport,
          route: route,
        ),
      ),
    );

    return _HelpScaffold(
      titleKey: "need_help.ask.title",
      children: [
        TilesCard(
          children: [
            _HelpRow(
              icon: Icons.account_balance_outlined,
              title: _tr(context, "need_help.ask.organisation"),
              subtitle: _tr(context, "need_help.ask.organisation_subtitle"),
              onTap: () => go(HelpRoute.organisation),
            ),
            _HelpRow(
              icon: Icons.phone_iphone_rounded,
              title: _tr(context, "need_help.ask.app"),
              subtitle: _tr(context, "need_help.ask.app_subtitle"),
              onTap: () => go(HelpRoute.yivi),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactChooseOrganisation extends StatelessWidget {
  final NeedHelpContactScreen screen;

  const _ContactChooseOrganisation(this.screen);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return _HelpScaffold(
      titleKey: "need_help.organisation.choose_title",
      children: [
        _Inset(_Paragraph(_tr(context, "need_help.organisation.choose_body"))),
        SizedBox(height: theme.mediumSpacing),
        _OrganisationChoices(
          onSelect: (org) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NeedHelpContactScreen(
                problem: screen.problem,
                organisation: org,
                errorCode: screen.errorCode,
                errorReport: screen.errorReport,
                route: screen.route,
              ),
            ),
          ),
        ),
        SizedBox(height: theme.mediumSpacing),
        _YiviFallback(screen),
      ],
    );
  }
}

/// The organisations the user recently dealt with, including sessions they
/// never finished, and always a search through all of them.
class _OrganisationChoices extends StatefulWidget {
  final void Function(SupportParty organisation) onSelect;

  const _OrganisationChoices({required this.onSelect});

  @override
  State<_OrganisationChoices> createState() => _OrganisationChoicesState();
}

class _OrganisationChoicesState extends State<_OrganisationChoices> {
  HistoryRepository? _history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_history != null) return;
    final repo = IrmaRepositoryProvider.of(context);
    _history = HistoryRepository(repo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) repo.bridgedDispatch(LoadLogsEvent(max: 20));
    });
  }

  @override
  void dispose() {
    _history?.dispose();
    super.dispose();
  }

  void _openSearch(IrmaConfiguration? config) {
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NeedHelpOrganisationSearchScreen(
          organisations: config == null
              ? const []
              : SupportParty.directory(config, lang),
          onSelect: widget.onSelect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);
    final config = SupportParty.configOf(repo);

    return StreamBuilder<HistoryState>(
      stream: _history!.getHistoryState(),
      builder: (context, snapshot) {
        // Sessions from memory show right away; the activity log joins
        // once it has loaded.
        final recent = recentOrganisations(
          sessions: repo.recentSessionParties,
          activity: snapshot.data?.logEntries ?? const [],
          config: config,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recent.isNotEmpty) ...[
              const SectionHeader("need_help.organisation.recent"),
              SizedBox(height: theme.smallSpacing),
              TilesCard(
                children: [
                  for (final r in recent)
                    _HelpRow(
                      leading: _OrganisationAvatar(r.organisation, size: 32),
                      title: r.organisation.name,
                      subtitle: r.unfinished
                          ? _tr(context, "need_help.organisation.unfinished")
                          : r.organisation.website?.host,
                      onTap: () => widget.onSelect(r.organisation),
                    ),
                ],
              ),
              SizedBox(height: theme.mediumSpacing),
            ],
            TilesCard(
              children: [
                _HelpRow(
                  key: const Key("need_help_search_organisation"),
                  icon: Icons.search_rounded,
                  title: _tr(
                    context,
                    recent.isEmpty
                        ? "need_help.organisation.search"
                        : "need_help.organisation.search_other",
                  ),
                  onTap: () => _openSearch(config),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Search through every organisation in the scheme, for one the user has
/// no recent session with.
class NeedHelpOrganisationSearchScreen extends StatefulWidget {
  final List<SupportParty> organisations;
  final void Function(SupportParty organisation) onSelect;

  const NeedHelpOrganisationSearchScreen({
    super.key,
    required this.organisations,
    required this.onSelect,
  });

  @override
  State<NeedHelpOrganisationSearchScreen> createState() =>
      _NeedHelpOrganisationSearchScreenState();
}

class _NeedHelpOrganisationSearchScreenState
    extends State<NeedHelpOrganisationSearchScreen> {
  final _focusNode = FocusNode();
  var _query = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<SupportParty> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.organisations;
    return [
      for (final org in widget.organisations)
        if (org.name.toLowerCase().contains(query) ||
            (org.website?.host.contains(query) ?? false))
          org,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final matches = _matches;
    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: YiviSearchBar(
        focusNode: _focusNode,
        onCancel: () => Navigator.of(context).pop(),
        onQueryChanged: (query) => setState(() => _query = query),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          children: [
            if (matches.isNotEmpty) ...[
              TilesCard(
                children: [
                  for (final org in matches)
                    _HelpRow(
                      leading: _OrganisationAvatar(org, size: 32),
                      title: org.name,
                      subtitle: org.website?.host,
                      onTap: () => widget.onSelect(org),
                    ),
                ],
              ),
              SizedBox(height: theme.defaultSpacing),
            ],
            _Inset(
              _Paragraph(_tr(context, "need_help.organisation.search_none")),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOrganisation extends StatelessWidget {
  final NeedHelpContactScreen screen;

  const _ContactOrganisation(this.screen);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final org = screen.organisation!;
    String tr(String key, [Map<String, String> params = const {}]) =>
        _tr(context, key, org: org, params: params);

    Future<void> open(Uri uri) async {
      try {
        await IrmaRepositoryProvider.of(
          context,
        ).openURLExternally(uri.toString());
      } catch (e, stacktrace) {
        reportError(e, stacktrace);
      }
    }

    final website = org.website;
    final email = org.email;

    return _HelpScaffold(
      title: tr("need_help.organisation.title"),
      children: [
        if (screen.problem.hasHandover) ...[
          _Inset(_Paragraph(tr(screen.problem.handoverKey))),
          SizedBox(height: theme.defaultSpacing),
        ],
        IrmaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _OrganisationAvatar(org, size: 48),
                  SizedBox(width: theme.defaultSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(org.name, style: theme.boldBody),
                        if (website != null || email != null)
                          Text(
                            website?.host ?? email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.neutralExtraDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (screen.errorCode != null) ...[
                SizedBox(height: theme.defaultSpacing),
                _Paragraph(
                  tr("need_help.organisation.quote_error_code", {
                    "code": screen.errorCode!,
                  }),
                ),
              ],
              SizedBox(height: theme.defaultSpacing),
              if (website != null)
                YiviThemedButton(
                  key: const Key("need_help_open_website_button"),
                  label: tr("need_help.organisation.open_website"),
                  style: YiviButtonStyle.filled,
                  onPressed: () => open(website),
                )
              else if (email != null)
                YiviThemedButton(
                  label: tr("need_help.organisation.send_email"),
                  style: YiviButtonStyle.filled,
                  onPressed: () => open(Uri(scheme: "mailto", path: email)),
                )
              else
                _Paragraph(tr("need_help.organisation.no_contact")),
              if (website != null && email != null) ...[
                SizedBox(height: theme.defaultSpacing),
                Center(
                  child: Link(
                    label: tr("need_help.organisation.or_email", {
                      "email": email,
                    }),
                    onTap: () => open(Uri(scheme: "mailto", path: email)),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Once there is a way to reach the organisation, that is the one
        // way forward. Without one, the user is not left stuck.
        if (website == null && email == null) ...[
          SizedBox(height: theme.mediumSpacing),
          _YiviFallback(screen),
        ],
      ],
    );
  }
}

/// For when it is the app after all, while no organisation to contact has
/// been found.
class _YiviFallback extends StatelessWidget {
  final NeedHelpContactScreen screen;

  const _YiviFallback(this.screen);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return _Inset(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IrmaDivider(),
          SizedBox(height: theme.defaultSpacing),
          _Paragraph(_tr(context, "need_help.organisation.app_not_working")),
          SizedBox(height: theme.tinySpacing),
          Link(
            key: const Key("need_help_yivi_fallback_link"),
            label: "need_help.yivi.mail_button",
            onTap: () => mailYiviSupport(
              context,
              topic: _tr(
                context,
                screen.problem.titleKey,
                org: screen.organisation,
              ),
              errorReport: screen.errorReport,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactYivi extends StatelessWidget {
  final NeedHelpContactScreen screen;

  const _ContactYivi(this.screen);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final org = screen.organisation;
    final problem = screen.problem;
    final topic = _tr(context, problem.titleKey, org: org);
    final withReport = screen.errorReport != null;

    Widget included(IconData icon, String text) => Padding(
      padding: EdgeInsets.only(top: theme.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.neutralExtraDark),
          SizedBox(width: theme.smallSpacing),
          Expanded(child: _Paragraph(text)),
        ],
      ),
    );

    return _HelpScaffold(
      titleKey: "need_help.yivi.title",
      children: [
        _Inset(
          _Paragraph(
            problem.hasHandover && problem.route == HelpRoute.yivi
                ? _tr(context, problem.handoverKey, org: org)
                : _tr(context, "need_help.yivi.body"),
          ),
        ),
        SizedBox(height: theme.defaultSpacing),
        IrmaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                "need_help.yivi.included",
                style: theme.boldBody,
                isHeader: true,
              ),
              included(
                Icons.label_outline_rounded,
                _tr(
                  context,
                  "need_help.yivi.included_topic",
                  params: {"topic": topic},
                ),
              ),
              included(
                Icons.phone_iphone_rounded,
                _tr(context, "need_help.yivi.included_device"),
              ),
              if (withReport)
                included(
                  Icons.description_outlined,
                  _tr(context, "need_help.yivi.included_report"),
                ),
              SizedBox(height: theme.defaultSpacing),
              YiviThemedButton(
                key: const Key("need_help_mail_yivi_button"),
                label: "need_help.yivi.mail_button",
                style: YiviButtonStyle.filled,
                onPressed: () => mailYiviSupport(
                  context,
                  topic: topic,
                  errorReport: screen.errorReport,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared layout ────────────────────────────────────────────────────────

class _HelpScaffold extends StatelessWidget {
  final String? titleKey;
  final String? title;
  final List<Widget> children;

  const _HelpScaffold({this.titleKey, this.title, required this.children})
    : assert((titleKey == null) != (title == null));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final style = theme.textTheme.displaySmall?.copyWith(
      color: theme.dark,
      height: 1.3,
    );
    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: "more_tab.need_help"),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.defaultSpacing,
                theme.smallSpacing,
                theme.defaultSpacing,
                theme.defaultSpacing,
              ),
              child: titleKey != null
                  ? TranslatedText(titleKey!, style: style, isHeader: true)
                  : Semantics(header: true, child: Text(title!, style: style)),
            ),
            ...children,
            SizedBox(height: theme.largeSpacing),
          ],
        ),
      ),
    );
  }
}

/// Text that lines up with the content inside the cards.
class _Inset extends StatelessWidget {
  final Widget child;

  const _Inset(this.child);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: IrmaTheme.of(context).defaultSpacing,
    ),
    child: child,
  );
}

class _Paragraph extends StatelessWidget {
  final String text;
  final bool small;

  const _Paragraph(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final base = small ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;
    return Text(text, style: base?.copyWith(color: theme.neutralExtraDark));
  }
}

class _HelpRow extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _HelpRow({
    super.key,
    this.leading,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Semantics(
      button: true,
      child: Material(
        child: ListTile(
          onTap: onTap,
          minLeadingWidth: theme.mediumSpacing,
          contentPadding: EdgeInsets.fromLTRB(
            theme.defaultSpacing,
            theme.tinySpacing,
            theme.smallSpacing,
            theme.tinySpacing,
          ),
          leading:
              leading ??
              (icon != null
                  ? Icon(icon, size: 28, color: theme.secondary)
                  : null),
          title: Text(
            title,
            style: theme.textButtonTextStyle.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.dark,
            ),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: EdgeInsets.only(top: theme.tinySpacing),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.neutralExtraDark,
                    ),
                  ),
                )
              : null,
          trailing: const Chevron(),
        ),
      ),
    );
  }
}

class _OrganisationAvatar extends StatelessWidget {
  final SupportParty organisation;
  final double size;

  const _OrganisationAvatar(this.organisation, {required this.size});

  @override
  Widget build(BuildContext context) {
    final party = organisation.party;
    final image = party.image;
    return IrmaAvatar(
      size: size,
      logoImage: image != null
          ? Base64Image(base64: image.base64, mimeType: image.mimeType)
          : null,
      logoPath: image == null ? party.imagePath : null,
      logoSemanticsLabel: party.name,
      initials: party.name.characters.firstOrNull,
    );
  }
}
