import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/digital_credentials.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/util/handle_pointer.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

Future<IrmaRepository> _repo(_RecordingBridge bridge) async {
  SharedPreferences.setMockInitialValues({});
  return IrmaRepository(
    client: bridge,
    preferences: await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    ),
  );
}

const _origin = "https://verifier.example";

DigitalCredentialsRequest _request({String? protocol}) =>
    DigitalCredentialsRequest(
      protocol: protocol ?? "openid4vp-v1-unsigned",
      origin: _origin,
      data: {
        "response_type": "vp_token",
        "response_mode": "dc_api",
        "nonce": "SkxpZ2h0",
        "dcql_query": {
          "credentials": [
            {"id": "pid", "format": "dc+sd-jwt"},
          ],
        },
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Digital Credentials API request wire format", () {
    // The Go core reads the request from `dc_api` on the session request. It
    // ignores `u` when that member is present, and `data` must arrive as a JSON
    // object because the core unmarshals it as the raw request parameters.
    test("a NewSessionEvent carries the request under dc_api", () {
      final pointer = SessionPointer.digitalCredentials(_request());
      final event = NewSessionEvent(sessionId: 7, request: pointer);

      final encoded = jsonDecode(jsonEncode(event)) as Map<String, dynamic>;
      final request = encoded["request"] as Map<String, dynamic>;

      expect(encoded["session_id"], 7);
      expect(request["protocol"], "openid4vp");
      expect(request["irmaqr"], "disclosing");
      expect(request["u"], "");
      expect(request["continue_on_second_device"], false);

      final dcApi = request["dc_api"] as Map<String, dynamic>;
      expect(dcApi["protocol"], "openid4vp-v1-unsigned");
      expect(dcApi["origin"], _origin);
      expect(dcApi["data"], isA<Map<String, dynamic>>());
      expect(
        (dcApi["data"] as Map<String, dynamic>)["response_mode"],
        "dc_api",
      );
    });

    test("the protocol identifier is passed through untouched", () {
      final pointer = SessionPointer.digitalCredentials(
        _request(protocol: "openid4vp-v1-signed"),
      );
      final dcApi =
          (jsonDecode(jsonEncode(pointer)) as Map<String, dynamic>)["dc_api"]
              as Map<String, dynamic>;
      expect(dcApi["protocol"], "openid4vp-v1-signed");
    });

    // Sessions that did arrive as a URL must not grow a dc_api member: it would
    // make the core read the request from there and ignore the URL.
    test("dc_api is absent for a pointer parsed from a URL", () {
      final pointer =
          Pointer.fromString(
                "openid4vp://?request_uri=https://verifier.example/req/abc"
                "&client_id=x509_san_dns:verifier.example",
              )
              as SessionPointer;

      expect(pointer.dcApi, isNull);
      expect(
        (jsonDecode(jsonEncode(pointer)) as Map<String, dynamic>).containsKey(
          "dc_api",
        ),
        isFalse,
      );
    });

    // Pointer.fromString feeds scanned QR JSON straight into
    // SessionPointer.fromJson, so a dc_api member there is attacker-chosen. The
    // origin it carries is what the Authorization Response is audience-bound to
    // and what the user is shown as the requestor, so the member must not be
    // readable at all.
    test("dc_api in a scanned QR payload is dropped", () {
      final qr = jsonEncode({
        "u": "https://verifier.example/irma/session/abc",
        "irmaqr": "disclosing",
        "protocol": "openid4vp",
        "dc_api": {
          "protocol": "openid4vp-v1-unsigned",
          "origin": "https://attacker.example",
          "data": {"nonce": "SkxpZ2h0"},
        },
      });

      final pointer =
          Pointer.fromString("irma://qr/json/$qr") as SessionPointer;

      expect(pointer.dcApi, isNull);
      expect(
        (jsonDecode(jsonEncode(pointer)) as Map<String, dynamic>).containsKey(
          "dc_api",
        ),
        isFalse,
      );
    });

    test("the pointer is a same-device openid4vp disclosure", () {
      final pointer = SessionPointer.digitalCredentials(_request());
      expect(pointer.protocol, Protocol.openid4vp);
      expect(pointer.irmaqr, "disclosing");
      expect(pointer.continueOnSecondDevice, isFalse);
      expect(pointer.openid4vciRedirectUri, isNull);
    });
  });

  group("Digital Credentials API events", () {
    test("HandleDigitalCredentialsRequestEvent parses the native payload", () {
      final event = HandleDigitalCredentialsRequestEvent.fromJson(
        jsonDecode('''
        {
          "request": {
            "protocol": "openid4vp-v1-signed",
            "origin": "$_origin",
            "data": {"request": "eyJhbGciOiJFUzI1NiJ9.e30.sig"}
          }
        }
        ''')
            as Map<String, dynamic>,
      );

      expect(event.request.protocol, "openid4vp-v1-signed");
      expect(event.request.origin, _origin);
      expect(event.request.data["request"], "eyJhbGciOiJFUzI1NiJ9.e30.sig");
    });

    test("DigitalCredentialsResponseEvent carries the response verbatim", () {
      const response = '{"vp_token":{"pid":["eyJ.eyJ.sig~"]}}';
      expect(
        jsonDecode(
          jsonEncode(DigitalCredentialsResponseEvent(response: response)),
        ),
        {"response": response},
      );
    });

    test("DigitalCredentialsFailureEvent names the reason", () {
      expect(
        jsonDecode(
          jsonEncode(
            DigitalCredentialsFailureEvent(
              reason: DigitalCredentialsFailureReason.cancelled,
            ),
          ),
        ),
        {"reason": "cancelled"},
      );
      expect(
        jsonDecode(
          jsonEncode(
            DigitalCredentialsFailureEvent(
              reason: DigitalCredentialsFailureReason.error,
            ),
          ),
        ),
        {"reason": "error"},
      );
    });

    test("a request from native is queued as a pending pointer", () async {
      final bridge = _RecordingBridge();
      final repo = await _repo(bridge);
      addTearDown(repo.close);

      repo.dispatch(HandleDigitalCredentialsRequestEvent(request: _request()));
      await pumpEventQueue();

      final pointer = repo.pendingPointer;
      expect(pointer, isA<SessionPointer>());
      expect((pointer as SessionPointer).dcApi?.origin, _origin);
      expect(pointer.protocol, Protocol.openid4vp);
    });
  });

  group("Digital Credentials API response", () {
    SessionState state({String? dcApiResponse}) => SessionState.fromJson(
      jsonDecode('''
      {
        "id": 1,
        "protocol": "openid4vp",
        "type": "disclosure",
        "status": "success",
        "requestor": {
          "id": "",
          "name": "verifier.example",
          "url": null,
          "parent": null,
          "verified": false
        },
        "offered_credential_types": null
        ${dcApiResponse == null ? "" : ', "dc_api_response": ${jsonEncode(dcApiResponse)}'}
      }
      ''')
          as Map<String, dynamic>,
    );

    test("dc_api_response is read off the session state", () {
      const response = '{"vp_token":{"pid":["eyJ.eyJ.sig~"]}}';
      expect(state(dcApiResponse: response).dcApiResponse, response);
    });

    test("a session without a Digital Credentials response has none", () {
      expect(state().dcApiResponse, isNull);
    });
  });

  // Nothing in a session's state says the request arrived through the Digital
  // Credentials API, except on the success leg. The repository remembers it, so
  // the screen can still report the endings that produce no response.
  group("Digital Credentials session bookkeeping", () {
    test(
      "the outcome of a marked session can be claimed exactly once",
      () async {
        final repo = await _repo(_RecordingBridge());
        addTearDown(repo.close);

        repo.markDigitalCredentialsSession(7);
        expect(repo.claimDigitalCredentialsSession(7), isTrue);
        expect(repo.claimDigitalCredentialsSession(7), isFalse);
      },
    );

    test("an unmarked session has no outcome to claim", () async {
      final repo = await _repo(_RecordingBridge());
      addTearDown(repo.close);

      repo.markDigitalCredentialsSession(7);
      expect(repo.claimDigitalCredentialsSession(8), isFalse);
    });

    /// Enough of an app to call [handlePointer]: it needs a repository in scope
    /// and a route to push the session screen onto.
    Future<BuildContext> mount(WidgetTester tester, IrmaRepository repo) async {
      late BuildContext context;
      final router = GoRouter(
        initialLocation: "/home",
        routes: [
          GoRoute(
            path: "/home",
            builder: (routeContext, _) {
              context = routeContext;
              return const SizedBox.shrink();
            },
          ),
          GoRoute(path: "/session", builder: (_, _) => const SizedBox.shrink()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
          child: IrmaRepositoryProvider(
            repository: repo,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      return context;
    }

    testWidgets("starting a session from a Digital Credentials request marks "
        "its id", (tester) async {
      final bridge = _RecordingBridge();
      final repo = await _repo(bridge);
      addTearDown(repo.close);

      final context = await mount(tester, repo);
      await handlePointer(
        context,
        SessionPointer.digitalCredentials(_request()),
      );
      await tester.pump();

      final started = bridge.dispatched.whereType<NewSessionEvent>().single;
      expect(repo.claimDigitalCredentialsSession(started.sessionId), isTrue);
    });

    testWidgets("starting a session from a URL marks nothing", (tester) async {
      final bridge = _RecordingBridge();
      final repo = await _repo(bridge);
      addTearDown(repo.close);

      final context = await mount(tester, repo);
      await handlePointer(
        context,
        Pointer.fromString(
              "openid4vp://?request_uri=https://verifier.example/req/abc"
              "&client_id=x509_san_dns:verifier.example",
            )
            as SessionPointer,
      );
      await tester.pump();

      final started = bridge.dispatched.whereType<NewSessionEvent>().single;
      expect(repo.claimDigitalCredentialsSession(started.sessionId), isFalse);
    });
  });
}
