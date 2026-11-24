// "Hulp nodig?": the one way into support.
//
//   1. What are you running into? The user picks a problem, or the one the
//      app already knows about when they came from an activity or an error.
//   2. The answer: what to do, in a few steps. Solved?
//   3. Only when it is not: who helps further. The problem decides who that
//      is: the organisation that issued or asked for the data, or Yivi
//      support. Yivi only answers for the app and the data it issues itself.
//
// Each step is a page of its own (in a form sheet on a tablet). From the
// More tab the first one can also sit in the tab's detail pane.

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/irma_repository_provider.dart";
import "../../sentry/sentry.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/input/search_input.dart";
import "../../widgets/surfaces/icon_square.dart";
import "../../widgets/surfaces/inset_group.dart";
import "../../widgets/surfaces/list_row.dart";
import "../../widgets/surfaces/numbered_step.dart";
import "../../widgets/surfaces/party_avatar.dart";
import "../../widgets/surfaces/surface_card.dart";
import "../more/widgets/more_subpage.dart";
import "help_problem.dart";
import "need_help_providers.dart";
import "support_party.dart";
import "yivi_support_mail.dart";

/// Where "Hulp nodig?" and its steps live. Every step's route starts with
/// it, so the whole flow can be closed at once.
const needHelpLocation = "/home/need_help";

/// Opens "Hulp nodig?" on top of what is open. With [helpContext], what the
/// app already knows is the first option.
Future<void> openNeedHelp(BuildContext context, {HelpContext? helpContext}) =>
    context.push<void>(needHelpLocation, extra: helpContext);

/// What a step after the first knows: the problem, and what came with it.
class NeedHelpStep {
  final HelpProblem problem;
  final SupportParty? organisation;
  final String? errorCode;
  final HelpErrorReport? errorReport;

  /// Overrides the problem's route, after the user answered "about what?".
  final HelpRoute? route;

  const NeedHelpStep({
    required this.problem,
    this.organisation,
    this.errorCode,
    this.errorReport,
    this.route,
  });

  NeedHelpStep copyWith({SupportParty? organisation, HelpRoute? route}) =>
      NeedHelpStep(
        problem: problem,
        organisation: organisation ?? this.organisation,
        errorCode: errorCode,
        errorReport: errorReport,
        route: route ?? this.route,
      );

  /// Who helps further: the problem's route, or the user's answer. Yivi's
  /// own data and requests: the organisation's support is Yivi's.
  HelpRoute get effectiveRoute {
    final r = route ?? problem.route;
    if (r == HelpRoute.organisation && (organisation?.isYivi ?? false)) {
      return HelpRoute.yivi;
    }
    return r;
  }
}

void _push(BuildContext context, String step, NeedHelpStep extra) =>
    context.push<void>("$needHelpLocation/$step", extra: extra);

void _openAnswer(BuildContext context, NeedHelpStep step) =>
    _push(context, step.problem.hasAnswer ? "answer" : "contact", step);

void _openContact(BuildContext context, NeedHelpStep step) =>
    _push(context, "contact", step);

/// Closes the whole flow, back to where it was opened: every step on top,
/// and its first page unless that sits in the More tab's pane.
void closeNeedHelp(BuildContext context) {
  final router = GoRouter.of(context);
  // The top match: a pushed step is a match of its own on top of the
  // location it was pushed from.
  bool inFlow() =>
      router
          .routerDelegate
          .currentConfiguration
          .matches
          .lastOrNull
          ?.matchedLocation
          .startsWith(needHelpLocation) ??
      false;
  while (router.canPop() && inFlow()) {
    router.pop();
  }
}

String _orgName(BuildContext context, SupportParty? org) =>
    org?.name ?? context.tr("need_help.the_organisation");

String _tr(
  BuildContext context,
  String key, {
  SupportParty? org,
  Map<String, String> params = const {},
}) => context.tr(key, {"org": _orgName(context, org), ...params});

Future<void> _openExternally(BuildContext context, Uri uri) async {
  try {
    await browserOf(context).openExternally(uri.toString());
  } catch (e, stacktrace) {
    reportError(e, stacktrace);
  }
}

// ─── 1. What are you running into? ────────────────────────────────────────

class NeedHelpScreen extends StatelessWidget {
  final HelpContext? helpContext;

  /// In the More tab's detail pane: no app bar, the title on the page.
  final bool embedded;

  const NeedHelpScreen({super.key, this.helpContext, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final known = helpContext;

    void open(
      HelpProblem problem, {
      SupportParty? organisation,
      String? errorCode,
    }) => _openAnswer(
      context,
      NeedHelpStep(
        problem: problem,
        organisation: organisation,
        errorCode: errorCode,
        // An error report stays with the request, whichever problem the
        // user picks: if it ends at Yivi, the report helps.
        errorReport: known?.errorReport,
      ),
    );

    return _NeedHelpPage(
      key: const Key("need_help_start"),
      embedded: embedded,
      title: context.tr("need_help.start.title"),
      children: [
        if (known != null)
          InsetGroup(
            header: context.tr(known.sectionKey),
            dividerIndent: 68,
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
        for (final (headerKey, problems) in HelpProblems.groups)
          InsetGroup(
            header: context.tr(headerKey),
            dividerIndent: 68,
            children: [
              for (final problem in problems)
                _HelpRow(
                  key: Key("need_help_problem_${problem.id}"),
                  icon: problem.icon,
                  title: _tr(context, problem.titleKey),
                  subtitle: problem.hasSubtitle
                      ? _tr(context, problem.subtitleKey)
                      : null,
                  onTap: () => open(problem),
                ),
            ],
          ),
        InsetGroup(
          children: [
            _HelpRow(
              key: const Key("need_help_problem_other"),
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
  final NeedHelpStep step;

  const NeedHelpAnswerScreen({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final problem = step.problem;
    String tr(String key) => _tr(context, key, org: step.organisation);

    return _NeedHelpPage(
      key: const Key("need_help_answer"),
      title: tr(problem.titleKey),
      children: [
        if (problem.hasLead) _Paragraph(tr(problem.leadKey)),
        if (problem.steps > 0)
          SurfaceCard(
            padding: const EdgeInsets.symmetric(
              horizontal: YiviSpace.x16,
              vertical: YiviSpace.x4,
            ),
            child: Column(
              children: [
                for (var i = 0; i < problem.steps; i++) ...[
                  if (i > 0) Divider(height: 1, color: palette.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: YiviSpace.x12,
                    ),
                    child: NumberedStep(
                      number: i + 1,
                      child: Text(tr(problem.stepKey(i))),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (problem.link case final link?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextLink(
              key: const Key("need_help_answer_link"),
              label: tr(problem.linkKey),
              onPressed: () => _openExternally(context, Uri.parse(link)),
            ),
          ),
        if (problem.hasNote) _Paragraph(tr(problem.noteKey)),
        if (step.errorCode case final code?)
          _Paragraph(
            _tr(context, "need_help.answer.error_code", params: {"code": code}),
            small: true,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x4,
            YiviSpace.x8,
            YiviSpace.x4,
            0,
          ),
          child: Semantics(
            header: true,
            child: Text(
              context.tr("need_help.answer.question"),
              style: palette.sectionHeader,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: YiviSpace.x12,
          children: [
            PrimaryPillButton(
              key: const Key("need_help_solved_button"),
              label: context.tr("need_help.answer.solved"),
              onPressed: () => closeNeedHelp(context),
            ),
            PillButton(
              key: const Key("need_help_not_solved_button"),
              label: context.tr("need_help.answer.not_solved"),
              size: PillSize.large,
              onPressed: () => _openContact(context, step),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 3. Who helps you further ─────────────────────────────────────────────

class NeedHelpContactScreen extends StatelessWidget {
  final NeedHelpStep step;

  const NeedHelpContactScreen({super.key, required this.step});

  @override
  Widget build(BuildContext context) => switch (step.effectiveRoute) {
    HelpRoute.ask => _ContactAsk(step),
    HelpRoute.yivi => _ContactYivi(step),
    HelpRoute.organisation =>
      step.organisation == null
          ? _ContactChooseOrganisation(step)
          : _ContactOrganisation(step),
  };
}

class _ContactAsk extends StatelessWidget {
  final NeedHelpStep step;

  const _ContactAsk(this.step);

  @override
  Widget build(BuildContext context) {
    // A fresh question: the organisation is the one the user picks next.
    void go(HelpRoute route) => _openContact(
      context,
      NeedHelpStep(
        problem: step.problem,
        errorReport: step.errorReport,
        route: route,
      ),
    );

    final problem = step.problem;
    return _NeedHelpPage(
      key: const Key("need_help_ask"),
      title: _tr(context, problem.askKey("title")),
      children: [
        InsetGroup(
          dividerIndent: 68,
          children: [
            _HelpRow(
              key: const Key("need_help_ask_organisation"),
              icon: Icons.account_balance_outlined,
              title: _tr(context, problem.askKey("organisation")),
              subtitle: _tr(context, problem.askKey("organisation_subtitle")),
              onTap: () => go(HelpRoute.organisation),
            ),
            _HelpRow(
              key: const Key("need_help_ask_app"),
              icon: Icons.phone_iphone_rounded,
              title: _tr(context, problem.askKey("app")),
              subtitle: _tr(context, problem.askKey("app_subtitle")),
              onTap: () => go(HelpRoute.yivi),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactChooseOrganisation extends ConsumerWidget {
  final NeedHelpStep step;

  const _ContactChooseOrganisation(this.step);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentOrganisationsProvider);
    void select(SupportParty org) =>
        _openContact(context, step.copyWith(organisation: org));

    return _NeedHelpPage(
      key: const Key("need_help_choose_organisation"),
      title: context.tr("need_help.organisation.choose_title"),
      children: [
        _Paragraph(_tr(context, step.problem.chooseOrganisationKey)),
        if (recent.isNotEmpty)
          InsetGroup(
            header: context.tr("need_help.organisation.recent"),
            dividerIndent: 68,
            children: [
              for (final r in recent)
                _HelpRow(
                  leading: _OrganisationAvatar(r.organisation),
                  title: r.organisation.name,
                  subtitle: r.unfinished
                      ? context.tr("need_help.organisation.unfinished")
                      : r.organisation.website?.host,
                  onTap: () => select(r.organisation),
                ),
            ],
          ),
        InsetGroup(
          dividerIndent: 68,
          children: [
            _HelpRow(
              key: const Key("need_help_search_organisation"),
              icon: Icons.search_rounded,
              title: context.tr(
                recent.isEmpty
                    ? "need_help.organisation.search"
                    : "need_help.organisation.search_other",
              ),
              onTap: () => _push(context, "search", step),
            ),
          ],
        ),
        _YiviFallback(step),
      ],
    );
  }
}

/// Search through every organisation in the schemes, for one the user has
/// no recent session with.
class NeedHelpOrganisationSearchScreen extends ConsumerStatefulWidget {
  final NeedHelpStep step;

  const NeedHelpOrganisationSearchScreen({super.key, required this.step});

  @override
  ConsumerState<NeedHelpOrganisationSearchScreen> createState() =>
      _NeedHelpOrganisationSearchScreenState();
}

class _NeedHelpOrganisationSearchScreenState
    extends ConsumerState<NeedHelpOrganisationSearchScreen> {
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

  List<SupportParty> _matches(List<SupportParty> all) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return all;
    return [
      for (final org in all)
        if (org.name.toLowerCase().contains(query) ||
            (org.website?.host.contains(query) ?? false))
          org,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(supportDirectoryProvider).value;
    final all = directory == null
        ? const <SupportParty>[]
        : SupportParty.directoryOf(directory, context.lang);
    final matches = _matches(all);

    return _NeedHelpPage(
      key: const Key("need_help_search"),
      titleKey: "need_help.organisation.search",
      children: [
        SearchInput(
          fieldKey: const Key("need_help_search_field"),
          hintKey: "need_help.organisation.search",
          focusNode: _focusNode,
          onChanged: (query) => setState(() => _query = query),
        ),
        if (matches.isNotEmpty)
          InsetGroup(
            dividerIndent: 68,
            children: [
              for (final org in matches)
                _HelpRow(
                  leading: _OrganisationAvatar(org),
                  title: org.name,
                  subtitle: org.website?.host,
                  onTap: () => _openContact(
                    context,
                    widget.step.copyWith(organisation: org),
                  ),
                ),
            ],
          ),
        _Paragraph(context.tr("need_help.organisation.search_none")),
      ],
    );
  }
}

class _ContactOrganisation extends ConsumerWidget {
  final NeedHelpStep step;

  const _ContactOrganisation(this.step);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    // Where it offers support comes from the schemes, which "Hulp nodig?"
    // asks for here: the steps before only knew the party.
    final directory = ref.watch(supportDirectoryProvider).value;
    final given = step.organisation!;
    final org = directory == null
        ? given
        : SupportParty.resolve(given.party, directory) ?? given;
    String tr(String key, [Map<String, String> params = const {}]) =>
        _tr(context, key, org: org, params: params);

    final website = org.website;
    final email = org.email;

    return _NeedHelpPage(
      key: const Key("need_help_organisation"),
      title: tr("need_help.organisation.title"),
      children: [
        if (step.problem.hasHandover) _Paragraph(tr(step.problem.handoverKey)),
        SurfaceCard(
          padding: const EdgeInsets.all(YiviSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x16,
            children: [
              Row(
                spacing: YiviSpace.x12,
                children: [
                  _OrganisationAvatar(org, size: 48),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(org.name, style: palette.sectionHeader),
                        if (email ?? website?.host case final contact?)
                          Text(
                            contact,
                            style: palette.rowSubtitle.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (step.errorCode case final code?)
                _Paragraph(
                  tr("need_help.organisation.quote_error_code", {"code": code}),
                ),
              if (email != null)
                PrimaryPillButton(
                  key: const Key("need_help_mail_organisation_button"),
                  label: tr("need_help.organisation.send_email"),
                  onPressed: () => mailOrganisation(
                    context,
                    email: email,
                    topic: tr(step.problem.titleKey),
                    errorCode: step.errorCode,
                  ),
                )
              else if (website != null)
                PrimaryPillButton(
                  key: const Key("need_help_open_website_button"),
                  label: tr("need_help.organisation.open_website"),
                  onPressed: () => _openExternally(context, website),
                )
              else
                _Paragraph(tr("need_help.organisation.no_contact")),
              if (website != null && email != null)
                Center(
                  child: TextLink(
                    key: const Key("need_help_open_website_link"),
                    label: tr("need_help.organisation.or_website"),
                    onPressed: () => _openExternally(context, website),
                  ),
                ),
            ],
          ),
        ),
        // An address the organisation gave is the one way forward. With no
        // address, or only a website guessed from a hostname, the user is
        // not left stuck.
        if (email == null && (website == null || org.websiteGuessed))
          _YiviFallback(step),
      ],
    );
  }
}

/// For when it is the app after all, while no organisation to contact has
/// been found.
class _YiviFallback extends StatelessWidget {
  final NeedHelpStep step;

  const _YiviFallback(this.step);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: palette.divider),
        const SizedBox(height: YiviSpace.x16),
        _Paragraph(context.tr("need_help.organisation.app_not_working")),
        TextLink(
          key: const Key("need_help_yivi_fallback_link"),
          label: context.tr("need_help.yivi.mail_button"),
          onPressed: () => mailYiviSupport(
            context,
            topic: _tr(context, step.problem.titleKey, org: step.organisation),
            errorReport: step.errorReport,
          ),
        ),
      ],
    );
  }
}

class _ContactYivi extends StatelessWidget {
  final NeedHelpStep step;

  const _ContactYivi(this.step);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final org = step.organisation;
    final problem = step.problem;
    final topic = _tr(context, problem.titleKey, org: org);

    Widget included(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: YiviSpace.x12,
      children: [
        Icon(icon, size: 20, color: palette.secondaryText),
        Expanded(child: _Paragraph(text)),
      ],
    );

    return _NeedHelpPage(
      key: const Key("need_help_yivi"),
      title: context.tr("need_help.yivi.title"),
      children: [
        _Paragraph(
          problem.hasHandover && problem.route == HelpRoute.yivi
              ? _tr(context, problem.handoverKey, org: org)
              : context.tr("need_help.yivi.body"),
        ),
        SurfaceCard(
          padding: const EdgeInsets.all(YiviSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x12,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.tr("need_help.yivi.included"),
                  style: palette.sectionHeader,
                ),
              ),
              included(
                Icons.label_outline_rounded,
                context.tr("need_help.yivi.included_topic", {"topic": topic}),
              ),
              included(
                Icons.phone_iphone_rounded,
                context.tr("need_help.yivi.included_device"),
              ),
              if (step.errorReport != null)
                included(
                  Icons.description_outlined,
                  context.tr("need_help.yivi.included_report"),
                ),
              const SizedBox(height: YiviSpace.x4),
              PrimaryPillButton(
                key: const Key("need_help_mail_yivi_button"),
                label: context.tr("need_help.yivi.mail_button"),
                onPressed: () => mailYiviSupport(
                  context,
                  topic: topic,
                  errorReport: step.errorReport,
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

/// A step of the flow: "Hulp nodig?" in the bar, the step's question or
/// title on the page, then its parts 24 apart.
class _NeedHelpPage extends StatelessWidget {
  final bool embedded;
  final String? title;

  /// The bar's title instead of "Hulp nodig?", with no title on the page.
  final String? titleKey;
  final List<Widget> children;

  const _NeedHelpPage({
    super.key,
    this.embedded = false,
    this.title,
    this.titleKey,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return MoreSubpage(
      embedded: embedded,
      titleKey: titleKey ?? "more_tab.need_help",
      top: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: YiviSpace.x24,
          children: [
            if (title case final title?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x4),
                child: Semantics(
                  header: true,
                  child: Text(title, style: palette.titleStep),
                ),
              ),
            ...children,
          ],
        ),
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  final bool small;

  const _Paragraph(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = small ? palette.paragraphSmall : palette.paragraph;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x4),
      child: Text(text, style: style.copyWith(color: palette.secondaryText)),
    );
  }
}

/// A row that opens the next step: an icon square or an organisation's
/// logo, the title, and a subtitle under it.
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
    final palette = YiviPalette.of(context);
    return ListRow(
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 99,
      leading:
          leading ??
          (icon == null
              ? null
              : IconSquare(
                  icon: icon!,
                  fill: palette.tint,
                  ink: palette.heading,
                  iconSize: 22,
                )),
      onTap: onTap,
    );
  }
}

class _OrganisationAvatar extends StatelessWidget {
  final SupportParty organisation;
  final double size;

  const _OrganisationAvatar(this.organisation, {this.size = 36});

  @override
  Widget build(BuildContext context) {
    final party = organisation.party;
    return PartyAvatar(
      name: party.name,
      size: size,
      image: party.image,
      imagePath: party.image == null ? party.imagePath : null,
    );
  }
}
