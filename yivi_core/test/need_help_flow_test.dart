import "dart:convert";
import "dart:io";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/error/session_error_screen.dart";
import "package:yivi_core/src/screens/help/help_screen.dart";
import "package:yivi_core/src/screens/need_help/help_problem.dart";
import "package:yivi_core/src/screens/need_help/need_help_screen.dart";
import "package:yivi_core/src/screens/need_help/support_party.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

/// The Dutch copy, to find texts by key: the tests check where the flow
/// leads, and that the organisation's name lands in the copy.
final Map<String, dynamic> _nl =
    json.decode(File("assets/locales/nl.json").readAsStringSync())
        as Map<String, dynamic>;

String t(String key, [Map<String, String> params = const {}]) {
  dynamic value = _nl;
  for (final part in key.split(".")) {
    value = (value as Map<String, dynamic>)[part];
  }
  var text = value as String;
  params.forEach((name, v) => text = text.replaceAll("{$name}", v));
  return text;
}

/// Known, but only reachable by email.
final _cis = SupportParty(party: _cisParty, email: "info@stichtingcis.nl");

final _cisParty = TrustedParty(
  id: "pbdf-requestors.cis",
  name: "Stichting CIS",
  url: null,
  parent: null,
  verified: true,
);

SupportParty _org({bool isYivi = false}) => SupportParty(
  party: _cisParty,
  website: Uri.https("stichtingcis.nl"),
  email: "info@stichtingcis.nl",
  isYivi: isYivi,
);

HelpContext _context(
  HelpProblem problem, {
  SupportParty? organisation,
  String? errorCode,
  HelpErrorReport? errorReport,
}) => HelpContext(
  sectionKey: "need_help.context.error_section",
  labelKey: "context label",
  problem: problem,
  organisation: organisation,
  errorCode: errorCode,
  errorReport: errorReport,
);

Widget _app(Widget home) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("nl", "NL"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ),
);

/// A screen that opens "Hulp nodig?", like the More tab or an error does.
class _Opener extends StatelessWidget {
  final HelpContext? helpContext;

  const _Opener({this.helpContext});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => openNeedHelp(context, helpContext: helpContext),
        child: const Text("open"),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _contextOption = find.byKey(const Key("need_help_context_option"));
final _notSolved = find.byKey(const Key("need_help_not_solved_button"));
final _mailYivi = find.byKey(const Key("need_help_mail_yivi_button"));
final _openWebsite = find.byKey(const Key("need_help_open_website_button"));

void main() {
  testWidgets("lists the problems, with what the app knows first", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpScreen(
        helpContext: _context(HelpProblems.outcome, organisation: _org()),
      ),
    );

    expect(find.text(t("need_help.start.title")), findsOneWidget);
    for (final (_, problems) in HelpProblems.groups) {
      for (final problem in problems) {
        expect(find.text(t(problem.titleKey)), findsOneWidget);
      }
    }
    expect(find.text(t(HelpProblems.other.titleKey)), findsOneWidget);

    final contextTop = tester.getTopLeft(_contextOption).dy;
    final firstProblemTop = tester
        .getTopLeft(find.text(t(HelpProblems.arrange.titleKey)))
        .dy;
    expect(contextTop, lessThan(firstProblemTop));
  });

  testWidgets("without context there is no context option", (tester) async {
    await _pump(tester, const NeedHelpScreen());
    expect(_contextOption, findsNothing);
  });

  testWidgets("solved closes the whole flow", (tester) async {
    await _pump(
      tester,
      _Opener(
        helpContext: _context(HelpProblems.outcome, organisation: _org()),
      ),
    );
    await _tap(tester, find.text("open"));
    await _tap(tester, _contextOption);
    expect(find.byType(NeedHelpAnswerScreen), findsOneWidget);

    await _tap(tester, find.byKey(const Key("need_help_solved_button")));
    expect(find.byType(NeedHelpAnswerScreen), findsNothing);
    expect(find.byType(NeedHelpScreen), findsNothing);
    expect(find.text("open"), findsOneWidget);
  });

  testWidgets("an organisation's problem goes to that organisation", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpScreen(
        helpContext: _context(
          HelpProblems.errorOrganisation,
          organisation: _org(),
          errorCode: "NEXT_SESSION",
        ),
      ),
    );
    await _tap(tester, _contextOption);
    expect(
      find.text(t("need_help.answer.error_code", {"code": "NEXT_SESSION"})),
      findsOneWidget,
    );

    await _tap(tester, _notSolved);
    expect(
      find.text(t("need_help.organisation.title", {"org": "Stichting CIS"})),
      findsOneWidget,
    );
    expect(_openWebsite, findsOneWidget);
    expect(
      find.text(
        t("need_help.organisation.quote_error_code", {"code": "NEXT_SESSION"}),
      ),
      findsOneWidget,
    );
    expect(_mailYivi, findsNothing);
    // For when it is the app after all.
    expect(
      find.byKey(const Key("need_help_yivi_fallback_link")),
      findsOneWidget,
    );
  });

  testWidgets("an organisation with only an email gets a mail button", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(problem: HelpProblems.outcome, organisation: _cis),
    );
    expect(_openWebsite, findsNothing);
    expect(
      find.text(
        t("need_help.organisation.send_email", {"org": "Stichting CIS"}),
      ),
      findsOneWidget,
    );
  });

  testWidgets("Yivi's own requests go to Yivi support", (tester) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        problem: HelpProblems.outcome,
        organisation: _org(isYivi: true),
      ),
    );
    expect(_mailYivi, findsOneWidget);
    expect(_openWebsite, findsNothing);
  });

  testWidgets("an unclear error goes to Yivi, with the error report", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpScreen(
        helpContext: _context(
          HelpProblems.errorUnknown,
          organisation: _org(),
          errorReport: const HelpErrorReport(
            details: "serverResponse",
            reportable: true,
          ),
        ),
      ),
    );
    await _tap(tester, _contextOption);
    await _tap(tester, _notSolved);

    expect(_mailYivi, findsOneWidget);
    expect(_openWebsite, findsNothing);
    expect(find.text(t("need_help.yivi.included_report")), findsOneWidget);
  });

  testWidgets("an app problem goes to Yivi, without a report", (tester) async {
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.text(t(HelpProblems.pin.titleKey)));
    await _tap(tester, _notSolved);

    expect(_mailYivi, findsOneWidget);
    expect(find.text(t("need_help.yivi.included_report")), findsNothing);
  });

  testWidgets("the FAQ is part of Hulp nodig?, and leads back to it", (
    tester,
  ) async {
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.byKey(const Key("need_help_faq_option")));
    expect(find.byType(HelpScreen), findsOneWidget);

    await _tap(tester, find.byKey(const Key("faq_need_help_link")));
    expect(find.byType(HelpScreen), findsNothing);
    expect(find.text(t("need_help.start.title")), findsOneWidget);
  });

  testWidgets("something else: the user says what it is about", (tester) async {
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.text(t(HelpProblems.other.titleKey)));
    expect(find.text(t("need_help.ask.title")), findsOneWidget);

    await _tap(tester, find.text(t("need_help.ask.app")));
    expect(_mailYivi, findsOneWidget);
  });

  group("session errors", () {
    Future<void> pumpError(
      WidgetTester tester,
      SessionError error, {
      SupportParty? organisation,
    }) => _pump(
      tester,
      SessionErrorScreen(
        error: error,
        onTapClose: () {},
        organisation: organisation,
      ),
    );

    testWidgets("offer Hulp nodig? instead of sending a report", (
      tester,
    ) async {
      await pumpError(
        tester,
        SessionError(errorType: "serverResponse", info: ""),
        organisation: _org(),
      );
      expect(find.text(t("more_tab.need_help")), findsOneWidget);
      expect(find.text(t("error.button_send_to_irma")), findsNothing);
      expect(
        find.text(t("error.types.unknown_body", {"org": "Stichting CIS"})),
        findsOneWidget,
      );

      await _tap(tester, find.text(t("more_tab.need_help")));
      expect(find.byType(NeedHelpScreen), findsOneWidget);
      expect(find.text(t("need_help.context.error_unknown")), findsOneWidget);
    });

    testWidgets("name the organisation when it caused the error", (
      tester,
    ) async {
      await pumpError(
        tester,
        SessionError(
          errorType: "api",
          info: "",
          remoteError: RemoteError(errorName: "NEXT_SESSION"),
        ),
        organisation: _org(),
      );
      expect(
        find.text(t("error.types.organisation", {"org": "Stichting CIS"})),
        findsOneWidget,
      );

      await _tap(tester, find.text(t("more_tab.need_help")));
      await _tap(tester, _contextOption);
      await _tap(tester, _notSolved);
      expect(_openWebsite, findsOneWidget);
    });

    testWidgets("say it is Yivi when it is", (tester) async {
      await pumpError(tester, SessionError(errorType: "keyshare", info: ""));
      expect(find.text(t("error.types.yivi")), findsOneWidget);
      expect(
        find.text(t("error.types.yivi_body_no_organisation")),
        findsOneWidget,
      );
    });
  });
}
