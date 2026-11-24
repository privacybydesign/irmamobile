import "dart:convert";
import "dart:io";

import "package:flutter_riverpod/misc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/support_directory.dart";
import "package:yivi_core/src/screens/error/session_error_screen.dart";
import "package:yivi_core/src/screens/need_help/help_problem.dart";
import "package:yivi_core/src/screens/need_help/need_help_providers.dart";
import "package:yivi_core/src/screens/need_help/need_help_screen.dart";
import "package:yivi_core/src/screens/need_help/support_party.dart";
import "package:yivi_core/src/screens/need_help/yivi_support_mail.dart";

import "support/onboarding_v2_harness.dart";

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

/// Kavelwinkel Almere as the scheme has it: a requestor without an issuer,
/// on a hostname of its supplier. The site behind that hostname is not the
/// organisation's.
SupportParty _kavelwinkel({String? supportEmail, String? supportUrl}) =>
    SupportParty.resolve(
      TrustedParty(
        id: "pbdf-requestors.kavelwinkel-almere",
        name: "Kavelwinkel Almere",
        url: null,
        parent: null,
        verified: true,
      ),
      SupportDirectory(
        requestors: [
          SupportRequestor(
            id: "pbdf-requestors.kavelwinkel-almere",
            hostnames: const ["almere-irma-prod.level-level.nl"],
            verified: true,
            supportEmail: supportEmail,
            supportUrl: supportUrl,
          ),
        ],
      ),
    )!;

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

/// "Hulp nodig?"'s routes as the app has them, under a page with [home].
List<RouteBase> _routes(Widget home) => [
  GoRoute(path: "/", builder: (_, _) => home),
  GoRoute(
    path: "/home",
    builder: (_, _) => const SizedBox(),
    routes: [
      GoRoute(
        path: "need_help",
        builder: (_, state) =>
            NeedHelpScreen(helpContext: state.extra as HelpContext?),
        routes: [
          GoRoute(
            path: "answer",
            builder: (_, state) =>
                NeedHelpAnswerScreen(step: state.extra! as NeedHelpStep),
          ),
          GoRoute(
            path: "contact",
            builder: (_, state) =>
                NeedHelpContactScreen(step: state.extra! as NeedHelpStep),
          ),
          GoRoute(
            path: "search",
            builder: (_, state) => NeedHelpOrganisationSearchScreen(
              step: state.extra! as NeedHelpStep,
            ),
          ),
        ],
      ),
    ],
  ),
];

/// The schemes "Hulp nodig?" asks for: none, unless a test gives them.
Override _directory(SupportDirectory? directory) =>
    supportDirectoryProvider.overrideWith(
      (ref) => directory == null
          ? const Stream<SupportDirectory>.empty()
          : Stream.value(directory),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  SupportDirectory? directory,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = IrmaRepository(
    client: RecordingBridge(),
    preferences: await freshPreferences(),
  );
  addTearDown(repo.close);
  await pumpRoutes(
    tester,
    repo: repo,
    routes: _routes(home),
    initialLocation: "/",
    locale: const Locale("nl", "NL"),
    overrides: [_directory(directory)],
  );
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
final _mailOrganisation = find.byKey(
  const Key("need_help_mail_organisation_button"),
);
final _websiteLink = find.byKey(const Key("need_help_open_website_link"));
final _yiviFallback = find.byKey(const Key("need_help_yivi_fallback_link"));

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
    // Mailing the organisation comes first, its website second.
    expect(_mailOrganisation, findsOneWidget);
    expect(_websiteLink, findsOneWidget);
    expect(_openWebsite, findsNothing);
    expect(
      find.text(
        t("need_help.organisation.quote_error_code", {"code": "NEXT_SESSION"}),
      ),
      findsOneWidget,
    );
    expect(_mailYivi, findsNothing);
    // The organisation is the one way forward.
    expect(_yiviFallback, findsNothing);
  });

  testWidgets("an organisation without contact details still leaves Yivi", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: SupportParty(party: _cisParty),
        ),
      ),
    );
    expect(_openWebsite, findsNothing);
    expect(
      find.text(
        t("need_help.organisation.no_contact", {"org": "Stichting CIS"}),
      ),
      findsOneWidget,
    );
    expect(_yiviFallback, findsOneWidget);
  });

  testWidgets("an organisation with only a website gets a website button", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: SupportParty(
            party: _cisParty,
            website: Uri.https("stichtingcis.nl"),
          ),
        ),
      ),
    );
    expect(_openWebsite, findsOneWidget);
    expect(_mailOrganisation, findsNothing);
    expect(_yiviFallback, findsNothing);
  });

  testWidgets("a website guessed from a hostname still leaves Yivi", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: SupportParty(
            party: _cisParty,
            website: Uri.https("level-level.nl"),
            websiteGuessed: true,
          ),
        ),
      ),
    );
    expect(_openWebsite, findsOneWidget);
    expect(_yiviFallback, findsOneWidget);
  });

  testWidgets("a requestor without a support address in the scheme", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: _kavelwinkel(),
        ),
      ),
    );
    // Only its supplier's site is known, so Yivi stays within reach.
    expect(find.text("level-level.nl"), findsOneWidget);
    expect(_openWebsite, findsOneWidget);
    expect(_mailOrganisation, findsNothing);
    expect(_yiviFallback, findsOneWidget);
  });

  testWidgets("a support address in the scheme gets the mail button", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: _kavelwinkel(
            supportEmail: "kavelwinkel@almere.example",
            supportUrl: "https://almere.example/kavelwinkel/contact",
          ),
        ),
      ),
    );
    expect(find.text("kavelwinkel@almere.example"), findsOneWidget);
    expect(_mailOrganisation, findsOneWidget);
    expect(
      find.text(
        t("need_help.organisation.send_email", {"org": "Kavelwinkel Almere"}),
      ),
      findsOneWidget,
    );
    // Its support page is the link below, and the supplier's site is gone.
    expect(_websiteLink, findsOneWidget);
    expect(_openWebsite, findsNothing);
    expect(find.text("level-level.nl"), findsNothing);
    // The organisation is the one way forward.
    expect(_yiviFallback, findsNothing);
  });

  testWidgets("a support page in the scheme is not a guessed website", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: _kavelwinkel(
            supportUrl: "https://almere.example/kavelwinkel/contact",
          ),
        ),
      ),
    );
    expect(find.text("almere.example"), findsOneWidget);
    expect(_openWebsite, findsOneWidget);
    expect(_mailOrganisation, findsNothing);
    expect(_yiviFallback, findsNothing);
  });

  test("the mail to an organisation names the problem and the error code", () {
    String body({String? errorCode}) => organisationMailBody(
      prompt: "Beschrijf hier je vraag of probleem:",
      topicLabel: "Onderwerp",
      topic: "Mijn aanvraag is afgewezen",
      errorCodeLabel: "Foutcode",
      errorCode: errorCode,
      sentFrom: "Verstuurd vanuit de Yivi-app",
    );

    expect(
      body(errorCode: "NEXT_SESSION"),
      "Beschrijf hier je vraag of probleem:\n\n\n\n---\n"
      "Onderwerp: Mijn aanvraag is afgewezen\n"
      "Foutcode: NEXT_SESSION\n"
      "Verstuurd vanuit de Yivi-app",
    );
    expect(body(), isNot(contains("Foutcode")));

    // Spaces as %20: mail apps show a "+" as is.
    expect(
      mailtoUri(
        address: "info@stichtingcis.nl",
        subject: "Hulp nodig: a & b",
        body: "regel 1\nregel 2",
      ),
      "mailto:info@stichtingcis.nl"
      "?subject=Hulp%20nodig%3A%20a%20%26%20b"
      "&body=regel%201%0Aregel%202",
    );
  });

  testWidgets("an organisation with only an email gets a mail button", (
    tester,
  ) async {
    await _pump(
      tester,
      NeedHelpContactScreen(
        step: NeedHelpStep(problem: HelpProblems.outcome, organisation: _cis),
      ),
    );
    expect(_openWebsite, findsNothing);
    expect(_websiteLink, findsNothing);
    expect(_yiviFallback, findsNothing);
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
        step: NeedHelpStep(
          problem: HelpProblems.outcome,
          organisation: _org(isYivi: true),
        ),
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
          errorReport: HelpErrorReport(
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

  testWidgets("search finds any organisation by name or website", (
    tester,
  ) async {
    final directory = SupportDirectory(
      requestors: [
        SupportRequestor(
          id: "pbdf-requestors.cis",
          name: const {"nl": "Stichting CIS"},
          hostnames: const ["inzage.stichtingcis.nl"],
          verified: true,
        ),
        SupportRequestor(
          id: "pbdf-requestors.vgz",
          name: const {"nl": "VGZ"},
          hostnames: const ["irma.vgz.nl"],
          verified: true,
        ),
        // Demo schemes are not searched.
        SupportRequestor(
          id: "irma-demo-requestors.demo",
          name: const {"nl": "Demo"},
          demo: true,
        ),
      ],
    );
    await _pump(
      tester,
      const NeedHelpOrganisationSearchScreen(
        step: NeedHelpStep(problem: HelpProblems.outcome),
      ),
      directory: directory,
    );
    final field = find.byKey(const Key("need_help_search_field"));
    // Without a query, everything is listed.
    expect(find.text("Stichting CIS"), findsOneWidget);
    expect(find.text("VGZ"), findsOneWidget);
    expect(find.text("Demo"), findsNothing);

    await tester.enterText(field, "cis");
    await tester.pumpAndSettle();
    expect(find.text("Stichting CIS"), findsOneWidget);
    expect(find.text("VGZ"), findsNothing);

    await tester.enterText(field, "vgz.nl");
    await tester.pumpAndSettle();
    expect(find.text("VGZ"), findsOneWidget);

    await tester.enterText(field, "onbekend");
    await tester.pumpAndSettle();
    expect(find.text("VGZ"), findsNothing);
    expect(find.text(t("need_help.organisation.search_none")), findsOneWidget);

    await tester.enterText(field, "vgz");
    await tester.pumpAndSettle();
    await _tap(tester, find.text("VGZ"));
    // Its contact step, with its site from the scheme's hostname.
    expect(
      find.text(t("need_help.organisation.title", {"org": "VGZ"})),
      findsOneWidget,
    );
    expect(find.text("vgz.nl"), findsOneWidget);
  });

  testWidgets("something else: the user says what it is about", (tester) async {
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.text(t(HelpProblems.other.titleKey)));
    expect(find.text(t("need_help.ask.title")), findsOneWidget);

    await _tap(tester, find.text(t("need_help.ask.app")));
    expect(_mailYivi, findsOneWidget);
  });

  testWidgets("adding data: the answer first, then where the data comes from", (
    tester,
  ) async {
    const problem = HelpProblems.addData;
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.text(t(problem.titleKey)));
    expect(find.text(t(problem.leadKey)), findsOneWidget);

    await _tap(tester, _notSolved);
    expect(find.text(t(problem.askKey("title"))), findsOneWidget);
    // Data from another organisation goes to that organisation.
    expect(find.text(t(problem.askKey("organisation"))), findsOneWidget);
    expect(
      t(problem.chooseOrganisationKey),
      isNot(t("need_help.organisation.choose_body")),
    );

    // Data Yivi issues goes to Yivi.
    await _tap(tester, find.text(t(problem.askKey("app"))));
    expect(_mailYivi, findsOneWidget);
  });

  testWidgets("a lost phone links to MyYivi", (tester) async {
    await _pump(tester, const NeedHelpScreen());
    await _tap(tester, find.text(t(HelpProblems.phone.titleKey)));

    final link = find.byKey(const Key("need_help_answer_link"));
    expect(link, findsOneWidget);
    expect(
      find.descendant(
        of: link,
        matching: find.text(t(HelpProblems.phone.linkKey)),
      ),
      findsOneWidget,
    );
    expect(HelpProblems.phone.link, "https://my.yivi.app");
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

    group("still let the user send the report without asking for help", () {
      final sendReport = find.byKey(const Key("error_send_report_link"));
      final reportSent = find.byKey(const Key("error_report_sent"));

      testWidgets("for an unclear error", (tester) async {
        await pumpError(
          tester,
          SessionError(errorType: "serverResponse", info: ""),
          organisation: _org(),
        );
        expect(find.text(t("error.button_send_report")), findsOneWidget);

        await _tap(tester, sendReport);
        // Without a Sentry DSN, reportError hands the report to Flutter.
        expect(tester.takeException(), "serverResponse");
        expect(sendReport, findsNothing);
        expect(reportSent, findsOneWidget);
        expect(find.text(t("error.report_sent")), findsOneWidget);
        expect(find.text(t("more_tab.need_help")), findsOneWidget);
      });

      testWidgets("for an error the organisation caused", (tester) async {
        await pumpError(
          tester,
          SessionError(
            errorType: "api",
            info: "",
            remoteError: RemoteError(errorName: "NEXT_SESSION"),
          ),
          organisation: _org(),
        );

        await _tap(tester, sendReport);
        expect(tester.takeException(), contains("NEXT_SESSION"));
        expect(reportSent, findsOneWidget);
      });

      testWidgets("for an error in Yivi", (tester) async {
        await pumpError(tester, SessionError(errorType: "keyshare", info: ""));
        expect(sendReport, findsOneWidget);
      });

      testWidgets("unless the error may not be reported", (tester) async {
        await pumpError(
          tester,
          SessionError(errorType: "https", info: ""),
          organisation: _org(),
        );
        expect(
          find.text(t("error.types.organisation", {"org": "Stichting CIS"})),
          findsOneWidget,
        );
        expect(sendReport, findsNothing);
        expect(reportSent, findsNothing);
      });

      testWidgets("unless the session expired", (tester) async {
        await pumpError(
          tester,
          SessionError(
            errorType: "",
            info: "",
            remoteError: RemoteError(errorName: "SESSION_UNKNOWN"),
          ),
        );
        expect(sendReport, findsNothing);
      });
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
      expect(_mailOrganisation, findsOneWidget);
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

  group("an error report", () {
    late List<Object> reported;

    setUp(() {
      reported = [];
      final previous = FlutterError.onError;
      // Without a Sentry DSN, reportError hands the report to Flutter.
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = previous);
    });

    test("goes to Yivi once, from the error screen or the mail", () {
      final report = HelpErrorReport(
        details: "serverResponse",
        reportable: true,
      );
      expect(report.sent, isFalse);

      report.send();
      report.send();

      expect(reported, ["serverResponse"]);
      expect(report.sent, isTrue);
    });

    test("that may not leave the device is never sent", () {
      final report = HelpErrorReport(details: "https", reportable: false);

      report.send();

      expect(reported, isEmpty);
      expect(report.sent, isFalse);
    });
  });
}
