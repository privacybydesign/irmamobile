import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/nested_issuance_host_provider.dart";
import "package:yivi_core/src/screens/session/issue_flow/issue_flow_controller.dart";
import "package:yivi_core/src/screens/session/models/session_view.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";
import "support/session_harness.dart";

/// Counts the launch records cleared.
class _Repo extends RecordingRepository {
  _Repo({required super.client, required super.preferences});

  var cleared = 0;

  @override
  void clearInAppLaunches() {
    cleared++;
    super.clearInAppLaunches();
  }
}

/// What the flow asked of its sheet.
class _Host implements IssueFlowHost {
  final succeeded = <List<Credential>>[];
  var ended = 0;
  final over = <SessionView>[];
  final handedOver = <int>[];
  var takeOver = false;
  Completer<void> overClosed = Completer<void>();

  @override
  bool onSucceeded(List<Credential> cards) {
    succeeded.add(cards);
    return takeOver;
  }

  @override
  void onSessionEnded() => ended++;

  @override
  Future<void> showOverSheet(SessionView view) {
    over.add(view);
    return overClosed.future;
  }

  @override
  void handOver(int sessionId) => handedOver.add(sessionId);
}

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

CredentialDescriptor _type(String credentialId, {String? issueURL}) =>
    CredentialDescriptor(
      credentialId: credentialId,
      name: credentialId.split(".").last,
      issuer: _party("Issuer"),
      category: "Personal",
      attributes: const [],
      issueURL: issueURL ?? "https://issuer.example/issue",
    );

/// A card from a website, Yivi's own e-mail address, a document.
final _website = _type("pbdf.gemeente.personalData");
final _email = _type(
  "pbdf.sidn-pbdf.email",
  issueURL: "https://email-issuer.example/issue",
);
final _passport = _type(
  "pbdf.pbdf.passport",
  issueURL: "https://passport-issuer.example/issue",
);

final _card = testCredential(
  type: "pbdf.gemeente.personalData",
  hash: "issued",
  name: "Personal data",
);

SessionState _issuance(int id, SessionStatus status) => SessionState(
  id: id,
  protocol: "irma",
  type: SessionType.issuance,
  status: status,
  requestor: _party("Issuer"),
  offeredCredentials: [_card],
);

class _Flow {
  _Flow(this.container, this.repo, this.bridge, this.host, this.config);

  final ProviderContainer container;
  final _Repo repo;
  final RecordingBridge bridge;
  final _Host host;
  final IssueFlowConfig config;
  late final ProviderSubscription<IssueFlowState> sub = container.listen(
    issueFlowProvider(config),
    (_, _) {},
  );

  IssueFlowController get c {
    sub;
    return container.read(issueFlowProvider(config).notifier);
  }

  IssueFlowState get s => sub.read();

  List<Type> get steps => [for (final step in s.stack) step.runtimeType];

  List<int> get dismissed => [
    for (final e in bridge.dispatched.whereType<SessionUserInteractionEvent>())
      if (e.type == UserInteractionType.dismiss) e.sessionId,
  ];

  NestedIssuanceHost? get waiting => container.read(nestedIssuanceHostProvider);

  /// Sends [state] to the app, as Go does, and lets it arrive.
  Future<void> emit(SessionState state) async {
    repo.dispatch(SessionStateEvent(sessionState: state));
    await pumpEventQueue();
  }

  /// Stops listening: the provider goes, and with it what was left running.
  Future<void> dispose() async {
    sub.close();
    await pumpEventQueue();
  }
}

Future<_Flow> _flow({
  CredentialDescriptor? start,
  int? requestId,
  bool linking = false,
}) async {
  final bridge = RecordingBridge();
  final repo = _Repo(client: bridge, preferences: await freshPreferences());
  addTearDown(repo.close);
  final container = ProviderContainer(
    overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  final host = _Host();
  return _Flow(
    container,
    repo,
    bridge,
    host,
    IssueFlowConfig(
      host: host,
      requestId: requestId,
      linking: linking,
      start: start,
    ),
  );
}

/// On the website page of [_website], opened, waiting for the issuance.
Future<_Flow> _waiting() async {
  final f = await _flow();
  f.c
    ..open(_website)
    ..add(_website)
    ..websiteOpened();
  return f;
}

/// [_waiting], with issuance [id] in the sheet at [status].
Future<_Flow> _withSession(int id, SessionStatus status) async {
  final f = await _waiting();
  f.c.attach(id);
  await f.emit(_issuance(id, status));
  return f;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("starts", () {
    test("on the root page, or straight on a card's details", () async {
      final root = await _flow();
      expect(root.s.stack, isEmpty);
      expect(root.s.direct, isFalse);

      final direct = await _flow(start: _website);
      expect(direct.steps, [DetailsStep]);
      expect(direct.s.adding, _website);
      expect(direct.s.direct, isTrue);
      expect(direct.s.started, isFalse);
    });

    test("Add: the website page, Yivi's own steps or the document", () async {
      final f = await _flow();
      f.c
        ..open(_website)
        ..add(_website);
      expect(f.steps, [DetailsStep, WebsiteStep]);
      expect(f.s.opened, isFalse);
      // Only once the website opens does the sheet wait for a session.
      expect(f.waiting, isNull);
      f.c.websiteOpened();
      expect(f.s.opened, isTrue);
      expect(f.waiting, f.c);
      expect(f.s.started, isTrue);

      f.c
        ..leave()
        ..open(_email)
        ..add(_email);
      expect(f.s.contact, ContactFlow.email);
      expect(f.waiting, f.c);

      final linking = await _flow(linking: true);
      linking.c
        ..open(_email)
        ..add(_email);
      expect(linking.s.contact, ContactFlow.linkEmail);

      f.c
        ..leave()
        ..open(_passport)
        ..add(_passport);
      expect(f.steps, [DetailsStep, DocumentStepPage]);
    });
  });

  group("back, by the page on top", () {
    test("the details: the root page; opened on them, nothing (the sheet "
        "closes)", () async {
      final f = await _flow();
      f.c
        ..open(_website)
        ..back();
      expect(f.s.stack, isEmpty);

      final direct = await _flow(start: _website);
      direct.c.back();
      expect(direct.steps, [DetailsStep]);
    });

    test("the issuer's page over the details: the details", () async {
      final f = await _flow();
      f.c
        ..open(_website)
        ..openDetailsIssuer();
      expect(f.steps, [DetailsStep, DetailsIssuerStep]);
      f.c.back();
      expect(f.steps, [DetailsStep]);
    });

    test("the website page: the details; once opened, the wait ends and the "
        "launch record goes", () async {
      final f = await _flow();
      f.c
        ..open(_website)
        ..add(_website)
        ..back();
      expect(f.steps, [DetailsStep]);
      expect(f.repo.cleared, 0);

      f.c
        ..add(_website)
        ..websiteOpened()
        ..back();
      expect(f.steps, [DetailsStep]);
      expect(f.waiting, isNull);
      expect(f.repo.cleared, 1);
    });

    test("the e-mail address: the details", () async {
      final f = await _flow();
      f.c
        ..open(_email)
        ..add(_email)
        ..back();
      expect(f.steps, [DetailsStep]);
    });

    test("the document: the details", () async {
      final f = await _flow();
      f.c
        ..open(_passport)
        ..add(_passport)
        ..back();
      expect(f.steps, [DetailsStep]);
    });

    test("the offer: declines it, a step back at once", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      expect(f.steps, [DetailsStep, WebsiteStep, IssueSessionStep]);
      expect(f.s.lastOffer?.id, 5);
      f.c.back();
      expect(f.dismissed, [5]);
      expect(f.steps, [DetailsStep, WebsiteStep]);
      expect(f.s.sessionId, isNull);
      expect(f.s.lastOffer, isNull);
    });

    test("taken without a type: the offer only declines; irmago's answer "
        "ends it", () async {
      final f = await _flow();
      f.c
        ..takeSession()
        ..attach(5);
      await f.emit(_issuance(5, SessionStatus.requestPermission));
      f.c.back();
      expect(f.dismissed, [5]);
      expect(f.steps, [IssueSessionStep]);
      await f.emit(_issuance(5, SessionStatus.dismissed));
      expect(f.s.stack, isEmpty);
      expect(f.host.ended, 1);
    });

    test("the PIN: declines; irmago's answer goes a step back", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      await f.emit(_issuance(5, SessionStatus.requestPin));
      expect(f.steps, [DetailsStep, WebsiteStep, IssueSessionStep, PinStep]);
      expect(f.s.pin, isTrue);
      f.c.back();
      expect(f.dismissed, [5]);
      expect(f.s.pin, isTrue);
      await f.emit(_issuance(5, SessionStatus.dismissed));
      expect(f.steps, [DetailsStep, WebsiteStep]);
    });

    test(
      "the issuer's pages over the offer: back to what is under them",
      () async {
        final f = await _withSession(5, SessionStatus.requestPermission);
        f.c
          ..openIssuer()
          ..openIssuer(technical: true);
        expect(f.s.issuerDepth, 2);
        f.c.back();
        expect(f.s.issuerDepth, 1);
        f.c.back();
        expect(f.s.issuerDepth, 0);
        expect(f.steps.last, IssueSessionStep);
        expect(f.dismissed, isEmpty);
      },
    );

    test("Success: nothing, its way on is the way out", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      await f.emit(_issuance(5, SessionStatus.requestPin));
      await f.emit(_issuance(5, SessionStatus.success));
      // The PIN stays under Success.
      expect(f.steps, [
        DetailsStep,
        WebsiteStep,
        IssueSessionStep,
        PinStep,
        SuccessStep,
      ]);
      f.c.back();
      expect(f.steps.last, SuccessStep);
      expect(f.dismissed, isEmpty);
    });
  });

  group("the issuance", () {
    test("Success: the cards kept, the wait and launches end, the host is "
        "told", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      final cleared = f.repo.cleared;
      await f.emit(_issuance(5, SessionStatus.success));
      expect(f.s.added?.single.hash, _card.hash);
      expect(f.s.hasSession, isTrue);
      expect(f.s.started, isFalse);
      expect(f.waiting, isNull);
      expect(f.repo.cleared, cleared + 1);
      expect(f.host.succeeded.single.single.hash, _card.hash);
    });

    test("Add once: a second tap sends nothing", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      f.c
        ..grant()
        ..grant();
      expect(
        f.bridge.dispatched.whereType<SessionUserInteractionEvent>().where(
          (e) => e.type == UserInteractionType.permission,
        ),
        hasLength(1),
      );
      expect(f.s.granted, isTrue);
    });

    test("an error: over the sheet; closed, the sheet without the "
        "session", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      await f.emit(
        SessionState(
          id: 5,
          protocol: "irma",
          type: SessionType.issuance,
          status: SessionStatus.error,
          requestor: _party("Issuer"),
          error: SessionError(errorType: "transport", info: "x"),
        ),
      );
      expect(f.host.over.single, isA<SessionFailed>());
      expect(f.s.sessionId, 5);
      f.host.overClosed.complete();
      await pumpEventQueue();
      expect(f.steps, [DetailsStep, WebsiteStep]);
    });

    test("a request instead of an issuance: handed over", () async {
      final f = await _waiting();
      f.c.attach(5);
      await f.emit(
        SessionState(
          id: 5,
          protocol: "irma",
          type: SessionType.disclosure,
          status: SessionStatus.showPairingCode,
          requestor: _party("Shop"),
          pairingCode: "1234",
        ),
      );
      expect(f.host.handedOver, [5]);
      expect(f.s.sessionId, isNull);
    });

    test("attach replaces a session: the old one is declined, its pages "
        "go", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      f.c
        ..grant()
        ..openIssuer();
      f.c.attach(6);
      expect(f.dismissed, [5]);
      expect(f.steps, [DetailsStep, WebsiteStep, IssueSessionStep]);
      expect(f.s.sessionId, 6);
      expect(f.s.granted, isFalse);
      expect(f.s.lastOffer, isNull);
      // The old session is no longer followed.
      await f.emit(_issuance(5, SessionStatus.success));
      expect(f.s.added, isNull);
      await f.emit(_issuance(6, SessionStatus.requestPermission));
      expect(f.s.lastOffer?.id, 6);
    });

    test("for a request: the host waits for a session while that request "
        "is the waiting one", () async {
      final f = await _flow(requestId: 3);
      expect(f.c.underlyingSessionId, 3);
    });
  });

  group("starting over", () {
    test("reset after Success: the root page; opened on a card, it stays "
        "so", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      await f.emit(_issuance(5, SessionStatus.success));
      f.c.reset();
      expect(f.s.stack, isEmpty);
      expect(f.s.hasSession, isFalse);
      expect(f.dismissed, isEmpty);

      final direct = await _flow(start: _website);
      direct.c.reset();
      expect(direct.s.direct, isTrue);
      direct.c.showRoot();
      expect(direct.s.direct, isFalse);
    });

    test("stop adding: the session declined, only the details left", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      final cleared = f.repo.cleared;
      f.c.stopAdding();
      expect(f.dismissed, [5]);
      expect(f.steps, [DetailsStep]);
      expect(f.waiting, isNull);
      expect(f.repo.cleared, cleared + 1);
    });

    test("choose something else: the root page", () async {
      final f = await _flow(start: _website);
      f.c
        ..add(_website)
        ..websiteOpened()
        ..chooseOther();
      expect(f.s.stack, isEmpty);
      expect(f.s.direct, isFalse);
      expect(f.waiting, isNull);
    });

    test("retry after a card that does not count: the website again, not "
        "opened", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      f.c.retry();
      expect(f.dismissed, [5]);
      expect(f.steps, [DetailsStep, WebsiteStep]);
      expect(f.s.opened, isFalse);
    });
  });

  group("the sheet gone", () {
    test("ends what was left running: the session, the wait", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      f.c.detach();
      // Detached, it no longer takes a session.
      f.c.attach(6);
      expect(f.s.sessionId, 5);
      await f.dispose();
      expect(f.dismissed, [5]);
      expect(f.waiting, isNull);
    });

    test("closed while adding: also the launch record", () async {
      final f = await _waiting();
      final cleared = f.repo.cleared;
      f.c.startClosing();
      await f.dispose();
      expect(f.repo.cleared, cleared + 1);
      expect(f.waiting, isNull);
    });

    test("not after Success", () async {
      final f = await _withSession(5, SessionStatus.requestPermission);
      await f.emit(_issuance(5, SessionStatus.success));
      f.c.startClosing();
      await f.dispose();
      expect(f.dismissed, isEmpty);
    });
  });
}
