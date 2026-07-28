import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/credential_usage.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/translated_value.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

final _now = DateTime.utc(2026, 7, 1);

// StreamingSharedPreferences.instance is a process-wide singleton, so
// setMockInitialValues alone does not reset values between tests. clearAll()
// wipes the backing store, giving each test a clean slate.
Future<IrmaPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  await prefs.clearAll();
  return prefs;
}

Future<IrmaRepository> _repo(IrmaPreferences prefs) async =>
    IrmaRepository(client: _SilentBridge(), preferences: prefs);

SessionStateEvent _sessionState(int id, SessionStatus status) =>
    SessionStateEvent(
      sessionState: SessionState(
        id: id,
        protocol: "irma",
        type: SessionType.disclosure,
        status: status,
        requestor: TrustedParty(
          id: "requestor",
          name: const TranslatedValue.empty(),
          url: null,
          parent: null,
          verified: true,
        ),
      ),
    );

SessionUserInteractionEvent _permission(int id, List<String> hashes) =>
    SessionUserInteractionEvent.permission(
      sessionId: id,
      granted: true,
      disclosureChoices: [
        DisclosureDisconSelection(
          credentials: hashes
              .map(
                (hash) => SelectedCredential(
                  credentialId: "pbdf.sidn-pbdf.email",
                  credentialHash: hash,
                  attributePaths: const [],
                ),
              )
              .toList(),
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("CredentialUsage", () {
    test("survives an encode/decode round trip", () {
      final usage = {
        "a": CredentialUsage(count: 3, lastUsed: _now),
        "b": CredentialUsage(
          count: 1,
          lastUsed: _now.add(const Duration(days: 1)),
        ),
      };

      final decoded = CredentialUsage.decode(CredentialUsage.encode(usage));

      expect(decoded.keys, ["a", "b"]);
      expect(decoded["a"]!.count, 3);
      expect(decoded["a"]!.lastUsed.isAtSameMomentAs(_now), isTrue);
      expect(decoded["b"]!.count, 1);
    });

    test("reads nothing from an empty or unparsable blob", () {
      expect(CredentialUsage.decode(""), isEmpty);
      expect(CredentialUsage.decode("not json"), isEmpty);
      expect(CredentialUsage.decode("[1,2]"), isEmpty);
    });

    test("skips entries it cannot read, keeping the rest", () {
      final decoded = CredentialUsage.decode(
        '{"good":[2,1000],"short":[2],"typed":["2",1000],"zero":[0,1000]}',
      );

      expect(decoded.keys, ["good"]);
      expect(decoded["good"]!.count, 2);
    });
  });

  group("recordCredentialUsage", () {
    test("starts empty", () async {
      final prefs = await _freshPrefs();
      expect(prefs.getCredentialUsage(), isEmpty);
    });

    test("counts one disclosure per call and stamps the time", () async {
      final prefs = await _freshPrefs();

      await prefs.recordCredentialUsage(["hash-a"], now: _now);
      await prefs.recordCredentialUsage([
        "hash-a",
        "hash-b",
      ], now: _now.add(const Duration(days: 2)));

      final usage = prefs.getCredentialUsage();
      expect(usage["hash-a"]!.count, 2);
      expect(
        usage["hash-a"]!.lastUsed.isAtSameMomentAs(
          _now.add(const Duration(days: 2)),
        ),
        isTrue,
      );
      expect(usage["hash-b"]!.count, 1);
    });

    test("counts a hash once per session, however often it appears", () async {
      final prefs = await _freshPrefs();

      await prefs.recordCredentialUsage(["hash-a", "hash-a"], now: _now);

      expect(prefs.getCredentialUsage()["hash-a"]!.count, 1);
    });

    test("ignores empty hashes", () async {
      final prefs = await _freshPrefs();

      await prefs.recordCredentialUsage([""], now: _now);

      expect(prefs.getCredentialUsage(), isEmpty);
    });

    test("drops the least recently used once past the cap", () async {
      final prefs = await _freshPrefs();
      final max = IrmaPreferences.maxTrackedCredentialUsage;

      for (var i = 0; i < max; i++) {
        await prefs.recordCredentialUsage([
          "hash-$i",
        ], now: _now.add(Duration(minutes: i)));
      }
      await prefs.recordCredentialUsage([
        "newcomer",
      ], now: _now.add(Duration(minutes: max)));

      final usage = prefs.getCredentialUsage();
      expect(usage, hasLength(max));
      expect(usage.containsKey("newcomer"), isTrue);
      // hash-0 was the oldest, so it made room for the newcomer.
      expect(usage.containsKey("hash-0"), isFalse);
      expect(usage.containsKey("hash-1"), isTrue);
    });
  });

  group("disclosed credentials are counted when the session succeeds", () {
    test("a successful session counts every credential it disclosed", () async {
      final prefs = await _freshPrefs();
      final repo = await _repo(prefs);
      addTearDown(repo.close);

      repo.dispatch(_permission(1, ["hash-a", "hash-b"]));
      repo.dispatch(_sessionState(1, SessionStatus.success));
      await pumpEventQueue();

      final usage = prefs.getCredentialUsage();
      expect(usage["hash-a"]!.count, 1);
      expect(usage["hash-b"]!.count, 1);
    });

    test("an approval that then failed does not count", () async {
      final prefs = await _freshPrefs();
      final repo = await _repo(prefs);
      addTearDown(repo.close);

      repo.dispatch(_permission(1, ["hash-a"]));
      repo.dispatch(_sessionState(1, SessionStatus.error));
      await pumpEventQueue();

      expect(prefs.getCredentialUsage(), isEmpty);
    });

    test("a session that succeeds twice over is counted once", () async {
      final prefs = await _freshPrefs();
      final repo = await _repo(prefs);
      addTearDown(repo.close);

      repo.dispatch(_permission(1, ["hash-a"]));
      repo.dispatch(_sessionState(1, SessionStatus.success));
      repo.dispatch(_sessionState(1, SessionStatus.success));
      await pumpEventQueue();

      expect(prefs.getCredentialUsage()["hash-a"]!.count, 1);
    });

    test("a success without an approval on record counts nothing", () async {
      final prefs = await _freshPrefs();
      final repo = await _repo(prefs);
      addTearDown(repo.close);

      repo.dispatch(_sessionState(1, SessionStatus.success));
      await pumpEventQueue();

      expect(prefs.getCredentialUsage(), isEmpty);
    });
  });
}
