import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/missing_data_flow.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/missing_data_band.dart";

import "missing_data_fixtures.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final email = testDescriptor("email");
  final phone = testDescriptor("phone");
  final idCard = testDescriptor("idcard");
  final steps = [
    testStep([
      [email],
    ]),
    testStep([
      [phone],
    ]),
    testStep([
      [idCard],
    ]),
  ];

  /// The checklist screen keeps these alive while the user is in an issuance
  /// flow, and the band reads them.
  void watchSession(MissingDataHarness harness) {
    harness.container.listen(
      issueDuringDisclosureProvider(testSessionId),
      (_, _) {},
    );
  }

  void startFlow(MissingDataHarness harness, String credentialId) {
    harness.container
        .read(missingDataFlowProvider.notifier)
        .start(sessionId: testSessionId, credentialId: credentialId);
  }

  group("MissingDataBand", () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        routes: [
          GoRoute(
            path: "/",
            builder: (_, _) =>
                const Scaffold(body: MissingDataBand(height: 96)),
          ),
        ],
      );
    });

    testWidgets("is hidden until the user comes from the checklist", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));

      expect(find.byKey(const Key("missing_data_band")), findsNothing);

      startFlow(harness, "phone");
      await tester.pump();

      expect(find.byKey(const Key("missing_data_band")), findsOneWidget);
      expect(find.text("Voor Test Verifier · 0 van 3 klaar"), findsOneWidget);
    });

    testWidgets("reads as one line with what is being obtained", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps, issued: {"email"}));
      startFlow(harness, "phone");
      await tester.pump();
      final semantics = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel(
          "Voor Test Verifier, 1 van 3 klaar, nu: Cred phone",
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets("is hidden again when the flow is cleared", (tester) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      startFlow(harness, "phone");
      await tester.pump();

      harness.container.read(missingDataFlowProvider.notifier).clear();
      await tester.pump();

      expect(find.byKey(const Key("missing_data_band")), findsNothing);
    });

    testWidgets("counts what is in the app and follows the session", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      startFlow(harness, "phone");
      await tester.pump();

      await harness.emit(tester, testSession(steps: steps, issued: {"email"}));

      expect(find.text("Voor Test Verifier · 1 van 3 klaar"), findsOneWidget);
    });

    testWidgets("checks what is done, rings the current and dims the rest", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps, issued: {"email"}));
      startFlow(harness, "phone");
      await tester.pump();

      expect(
        find.byKey(const Key("missing_data_band_done_email")),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key("missing_data_band_done_phone")),
        findsNothing,
      );
      expect(
        find.byKey(const Key("missing_data_band_done_idcard")),
        findsNothing,
      );

      // Only the current one has a ring, in the primary colour.
      final ring = tester.widget<DecoratedBox>(
        find.byKey(const Key("missing_data_band_ring")),
      );
      expect(
        (ring.decoration as BoxDecoration).boxShadow?.first.color,
        IrmaThemeData().primary,
      );

      // Done and current at full strength, the one still to do dimmed.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity);
      expect(opacities, [1, 1, 0.4]);
    });
  });

  group("MissingDataBand height", () {
    Future<double> bandHeight(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late double height;
      final router = GoRouter(
        routes: [
          GoRoute(path: "/", builder: (_, _) => const Scaffold()),
          GoRoute(
            path: "/bar",
            builder: (context, _) {
              height = context.missingDataBand!.preferredSize.height;
              return const Scaffold();
            },
          ),
        ],
      );
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      startFlow(harness, "phone");
      router.push("/bar");
      await tester.pumpAndSettle();

      return height;
    }

    testWidgets("is one line of label tall where the label fits", (
      tester,
    ) async {
      expect(await bandHeight(tester, 800), 54);
    });

    testWidgets("grows by a line where the icons leave less room", (
      tester,
    ) async {
      expect(await bandHeight(tester, 390), 70);
    });
  });

  group("MissingDataBand in an app bar", () {
    testWidgets("fits its height at a large text size", (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final router = GoRouter(
        routes: [
          GoRoute(path: "/", builder: (_, _) => const Scaffold()),
          GoRoute(
            path: "/bar",
            builder: (context, _) => Scaffold(
              appBar: IrmaAppBar(
                titleTranslationKey: "missing_data.back_to_list",
                bottom: context.missingDataBand,
              ),
            ),
          ),
        ],
      );
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      startFlow(harness, "phone");
      router.push("/bar");
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("missing_data_band")), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("leaves the borders to the band", (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: "/", builder: (_, _) => const Scaffold()),
          GoRoute(
            path: "/bar",
            builder: (context, _) => Scaffold(
              appBar: IrmaAppBar(
                titleTranslationKey: "missing_data.back_to_list",
                bottom: context.missingDataBand,
              ),
            ),
          ),
        ],
      );
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      router.push("/bar");
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppBar>(find.byKey(const Key("irma_app_bar"))).shape,
        isNotNull,
      );

      startFlow(harness, "phone");
      router.pop();
      router.push("/bar");
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("missing_data_band")), findsOneWidget);
      expect(
        tester.widget<AppBar>(find.byKey(const Key("irma_app_bar"))).shape,
        isNull,
      );
    });

    testWidgets("adds nothing to the app bar outside the checklist", (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: "/", builder: (_, _) => const Scaffold()),
          GoRoute(
            path: "/bar",
            builder: (context, _) => Scaffold(
              appBar: IrmaAppBar(
                titleTranslationKey: "missing_data.back_to_list",
                bottom: context.missingDataBand,
              ),
            ),
          ),
        ],
      );
      await MissingDataHarness.pump(tester, router);
      router.push("/bar");
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("missing_data_band")), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key("irma_app_bar"))).height,
        kToolbarHeight,
      );
    });
  });

  group("issuance screens", () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const Scaffold(body: Text("session page")),
          ),
          GoRoute(
            path: "/details",
            builder: (_, _) => const Scaffold(body: Text("details page")),
          ),
          GoRoute(
            path: "/issue_email",
            builder: (_, _) => const EmailIssuanceScreen(),
          ),
        ],
      );
    });

    Future<MissingDataHarness> openEmailScreen(
      WidgetTester tester, {
      String? flowCredentialId,
    }) async {
      final harness = await MissingDataHarness.pump(tester, router);
      watchSession(harness);
      await harness.emit(tester, testSession(steps: steps));
      if (flowCredentialId != null) startFlow(harness, flowCredentialId);
      router.push("/details");
      await tester.pumpAndSettle();
      router.push("/issue_email");
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets("keep Annuleer and show no band outside the checklist", (
      tester,
    ) async {
      await openEmailScreen(tester);

      expect(find.text("Annuleer"), findsOneWidget);
      expect(find.text("Terug naar de lijst"), findsNothing);
      expect(find.byKey(const Key("missing_data_band")), findsNothing);
    });

    testWidgets("show the band and lead back to the list from the checklist", (
      tester,
    ) async {
      await openEmailScreen(tester, flowCredentialId: "email");

      expect(find.byKey(const Key("missing_data_band")), findsOneWidget);
      expect(find.text("Voor Test Verifier · 0 van 3 klaar"), findsOneWidget);
      expect(find.text("Annuleer"), findsNothing);
      expect(find.text("Terug naar de lijst"), findsOneWidget);

      await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
      await tester.pumpAndSettle();

      expect(find.text("session page"), findsOneWidget);
      expect(find.text("details page"), findsNothing);
      expect(find.byType(EmailIssuanceScreen), findsNothing);
    });
  });

  group("missingDataBack", () {
    late GoRouter router;
    var cancelled = 0;

    setUp(() {
      cancelled = 0;
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const Scaffold(body: Text("session page")),
          ),
          GoRoute(
            path: "/flow",
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: context.missingDataBack(() => cancelled++),
                child: const Text("back"),
              ),
            ),
          ),
        ],
      );
    });

    testWidgets("runs the cancel action outside the checklist", (tester) async {
      await MissingDataHarness.pump(tester, router);
      router.push("/flow");
      await tester.pumpAndSettle();

      await tester.tap(find.text("back"));
      await tester.pumpAndSettle();

      expect(cancelled, 1);
      expect(find.text("back"), findsOneWidget);
    });

    testWidgets("goes back to the session from the checklist", (tester) async {
      final harness = await MissingDataHarness.pump(tester, router);
      router.push("/flow");
      await tester.pumpAndSettle();
      startFlow(harness, "email");

      await tester.tap(find.text("back"));
      await tester.pumpAndSettle();

      expect(cancelled, 0);
      expect(find.text("session page"), findsOneWidget);
    });
  });
}
