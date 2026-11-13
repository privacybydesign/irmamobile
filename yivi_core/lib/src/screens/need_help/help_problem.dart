import "package:material_ui/material_ui.dart";

import "support_party.dart";

/// Who helps when the answer was not enough. [ask] lets the user say.
enum HelpRoute { organisation, yivi, ask }

/// A problem with its short answer. All texts live under
/// `need_help.problems.<id>` and may use `{org}`: the organisation's name,
/// or "the organisation" when the app doesn't know which one.
class HelpProblem {
  final String id;
  final IconData icon;
  final HelpRoute route;
  final int steps;
  final bool hasSubtitle;
  final bool hasLead;
  final bool hasNote;

  /// Shown above the contact options, to say why this party helps.
  final bool hasHandover;

  const HelpProblem({
    required this.id,
    required this.icon,
    required this.route,
    this.steps = 0,
    this.hasSubtitle = false,
    this.hasLead = true,
    this.hasNote = false,
    this.hasHandover = false,
  });

  String get _base => "need_help.problems.$id";
  String get titleKey => "$_base.title";
  String get subtitleKey => "$_base.subtitle";
  String get leadKey => "$_base.lead";
  String stepKey(int index) => "$_base.step_${index + 1}";
  String get noteKey => "$_base.note";
  String get handoverKey => "$_base.handover";
}

abstract final class HelpProblems {
  static const arrange = HelpProblem(
    id: "arrange",
    icon: Icons.account_balance_outlined,
    route: HelpRoute.organisation,
    steps: 4,
    hasSubtitle: true,
    hasNote: true,
    hasHandover: true,
  );

  static const outcome = HelpProblem(
    id: "outcome",
    icon: Icons.hourglass_empty_rounded,
    route: HelpRoute.organisation,
    steps: 2,
    hasSubtitle: true,
    hasNote: true,
    hasHandover: true,
  );

  static const addData = HelpProblem(
    id: "add_data",
    icon: Icons.add_circle_outline_rounded,
    route: HelpRoute.yivi,
    steps: 3,
    hasSubtitle: true,
    hasNote: true,
  );

  static const dataWrong = HelpProblem(
    id: "data_wrong",
    icon: Icons.rule_rounded,
    route: HelpRoute.yivi,
    steps: 3,
    hasSubtitle: true,
    hasHandover: true,
  );

  static const pin = HelpProblem(
    id: "pin",
    icon: Icons.lock_outline_rounded,
    route: HelpRoute.yivi,
    steps: 3,
  );

  static const phone = HelpProblem(
    id: "phone",
    icon: Icons.phone_iphone_rounded,
    route: HelpRoute.yivi,
    steps: 3,
  );

  static const appBroken = HelpProblem(
    id: "app_broken",
    icon: Icons.error_outline_rounded,
    route: HelpRoute.yivi,
    steps: 3,
    hasNote: true,
  );

  static const other = HelpProblem(
    id: "other",
    icon: Icons.chat_bubble_outline_rounded,
    route: HelpRoute.ask,
    hasLead: false,
  );

  /// Data an organisation issued: only that organisation can change it.
  static const dataFromOrganisation = HelpProblem(
    id: "data_from_organisation",
    icon: Icons.rule_rounded,
    route: HelpRoute.organisation,
    steps: 2,
    hasHandover: true,
  );

  static const errorYivi = HelpProblem(
    id: "error_yivi",
    icon: Icons.error_outline_rounded,
    route: HelpRoute.yivi,
    steps: 2,
    hasHandover: true,
  );

  static const errorOrganisation = HelpProblem(
    id: "error_organisation",
    icon: Icons.error_outline_rounded,
    route: HelpRoute.organisation,
    steps: 2,
    hasHandover: true,
  );

  static const errorUnknown = HelpProblem(
    id: "error_unknown",
    icon: Icons.error_outline_rounded,
    route: HelpRoute.yivi,
    steps: 3,
    hasHandover: true,
  );

  static const errorExpired = HelpProblem(
    id: "error_expired",
    icon: Icons.timer_off_outlined,
    route: HelpRoute.yivi,
    steps: 2,
    hasHandover: true,
  );

  /// The start screen's groups, each with a section header key.
  static const groups = [
    ("need_help.start.group_organisation", [arrange, outcome]),
    ("need_help.start.group_data", [addData, dataWrong]),
    ("need_help.start.group_app", [pin, phone, appBroken]),
  ];
}

/// The error behind a help request, sent along when the request ends at
/// Yivi support.
class HelpErrorReport {
  final String details;

  /// Whether the error may also go to Sentry. Matches the error screen's
  /// own reporting rules.
  final bool reportable;

  const HelpErrorReport({required this.details, required this.reportable});
}

/// What the app already knows when "Hulp nodig?" opens from an activity or
/// an error. It becomes the first option on the start screen.
class HelpContext {
  final String sectionKey;
  final String labelKey;

  /// Already translated, e.g. a date.
  final String? subtitle;
  final HelpProblem problem;
  final SupportParty? organisation;

  /// For errors that go to an organisation: the code to quote.
  final String? errorCode;
  final HelpErrorReport? errorReport;

  const HelpContext({
    required this.sectionKey,
    required this.labelKey,
    this.subtitle,
    required this.problem,
    this.organisation,
    this.errorCode,
    this.errorReport,
  });

  HelpContext withOrganisation(SupportParty organisation) => HelpContext(
    sectionKey: sectionKey,
    labelKey: labelKey,
    subtitle: subtitle,
    problem: problem,
    organisation: organisation,
    errorCode: errorCode,
    errorReport: errorReport,
  );
}
