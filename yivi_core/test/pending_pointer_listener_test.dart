// What happens to a queued pointer on the home screen: it waits while the
// app is locked, then starts its session once, on a session screen or in
// the sheet that waits for it.
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/nested_issuance_host_provider.dart";
import "package:yivi_core/src/routing/navigation.dart";
import "package:yivi_core/src/screens/home/widgets/pending_pointer_listener.dart";

import "support/onboarding_v2_harness.dart";

SessionPointer _pointer(String id) =>
    Pointer.fromString(
          '{"u":"https://example.com/irma/session/$id","irmaqr":"disclosing"}',
        )
        as SessionPointer;

class _Host implements NestedIssuanceHost {
  final attached = <int>[];

  @override
  int? get underlyingSessionId => null;

  @override
  void attach(int sessionId) => attached.add(sessionId);
}

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  /// Session ids of the session screens pushed, in order, once each.
  final pushed = <int>[];

  Future<void> pump(WidgetTester tester) async {
    pushed.clear();
    await pumpRoutes(
      tester,
      repo: repo,
      initialLocation: "/home",
      overrides: [emailLinkingOfferedProvider.overrideWithValue(true)],
      routes: [
        GoRoute(
          path: "/home",
          builder: (_, _) =>
              const Scaffold(body: PendingPointerListener(child: Text("home"))),
        ),
        GoRoute(
          path: "/session",
          builder: (_, state) {
            final args = SessionRouteParams.fromQueryParams(
              state.uri.queryParameters,
            );
            // A page is built again when another is pushed over it.
            if (!pushed.contains(args.sessionId)) pushed.add(args.sessionId);
            return Scaffold(body: Text("session ${args.sessionId}"));
          },
        ),
      ],
    );
    await settle(tester);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.text("home")));

  List<NewSessionEvent> started() =>
      bridge.dispatched.whereType<NewSessionEvent>().toList();

  testWidgets("15. a pointer waits while locked and starts once on "
      "unlock", (tester) async {
    await pump(tester);
    repo.pendingPointers.put(_pointer("a"));
    await settle(tester);

    expect(started(), isEmpty);
    expect(pushed, isEmpty);
    expect(repo.pendingPointers.current, isNotNull);

    repo.appLock.unlockLocally();
    await settle(tester);
    await settle(tester);

    expect(started(), hasLength(1));
    expect(started().single.request.u, "https://example.com/irma/session/a");
    expect(repo.pendingPointers.current, isNull);
    expect(pushed, [started().single.sessionId]);
    expect(find.text("session ${started().single.sessionId}"), findsOneWidget);

    // Locking and unlocking again starts nothing more.
    repo.appLock.lock();
    await settle(tester);
    repo.appLock.unlockLocally();
    await settle(tester);
    expect(started(), hasLength(1));
  });

  testWidgets("16. with a sheet waiting for a session, the sheet gets it "
      "and no screen is pushed", (tester) async {
    await pump(tester);
    final host = _Host();
    container(tester).read(nestedIssuanceHostProvider.notifier).register(host);
    repo.appLock.unlockLocally();
    await settle(tester);

    repo.pendingPointers.put(_pointer("a"));
    await settle(tester);
    await settle(tester);

    expect(started(), hasLength(1));
    expect(host.attached, [started().single.sessionId]);
    expect(pushed, isEmpty);
  });

  group("17. an e-mail link", () {
    final link = EmailCodePointer(email: "jan@example.com", code: "XYZ789");

    testWidgets("while linking is open goes to linking; the queue is "
        "cleared", (tester) async {
      await pump(tester);
      final c = container(tester);
      final keep = c.listen(
        contactIssuanceProvider(ContactFlow.linkEmail),
        (_, _) {},
      );
      addTearDown(keep.close);
      repo.appLock.unlockLocally();
      await settle(tester);

      repo.pendingPointers.put(link);
      await settle(tester);
      await settle(tester);

      expect(c.read(emailLinkingProvider).link, same(link));
      expect(repo.pendingPointers.current, isNull);
      expect(started(), isEmpty);
    });

    testWidgets("while an e-mail address is being added is dropped; the "
        "queue is cleared", (tester) async {
      await pump(tester);
      final c = container(tester);
      final keep = c.listen(
        contactIssuanceProvider(ContactFlow.email),
        (_, _) {},
      );
      addTearDown(keep.close);
      repo.appLock.unlockLocally();
      await settle(tester);

      repo.pendingPointers.put(link);
      await settle(tester);
      await settle(tester);

      expect(c.read(emailLinkingProvider).link, isNull);
      expect(repo.pendingPointers.current, isNull);
      expect(started(), isEmpty);
    });
  });

  testWidgets("18. a second pointer queued after the first started starts "
      "too", (tester) async {
    await pump(tester);
    repo.appLock.unlockLocally();
    await settle(tester);

    // A second link arrives as soon as the first one's session started.
    repo.pendingPointers.put(_pointer("a"));
    await settle(tester);
    repo.pendingPointers.put(_pointer("b"));
    await settle(tester);
    await settle(tester);

    expect(started().map((e) => e.request.u), [
      "https://example.com/irma/session/a",
      "https://example.com/irma/session/b",
    ]);
    expect(pushed, started().map((e) => e.sessionId));
    expect(repo.pendingPointers.current, isNull);
  });
}
