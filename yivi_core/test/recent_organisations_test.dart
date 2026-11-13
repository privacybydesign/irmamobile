import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/recent_session_parties.dart";
import "package:yivi_core/src/data/session_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/need_help/recent_organisations.dart";

TrustedParty _party(String id, [String? name]) => TrustedParty(
  id: id,
  name: name ?? id,
  url: null,
  parent: null,
  verified: true,
);

LogInfo _disclosure(TrustedParty verifier, DateTime time) => LogInfo(
  type: LogType.disclosure,
  time: time,
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: const [],
    verifier: verifier,
  ),
  signedMessageLog: null,
  removalLog: null,
);

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

SessionStateEvent _state(int id, SessionStatus status, TrustedParty party) =>
    SessionStateEvent(
      sessionState: SessionState(
        id: id,
        protocol: "irma",
        type: SessionType.disclosure,
        status: status,
        requestor: party,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("RecentSessionParties", () {
    test("keeps the latest state of each session", () {
      final parties = RecentSessionParties();
      final cis = _party("pbdf-requestors.cis");
      parties.record(1, cis, completed: false);
      parties.record(1, cis, completed: true);

      expect(parties.recent, hasLength(1));
      expect(parties.recent.single.completed, isTrue);
    });

    test("one entry per party, from its latest session, newest first", () {
      final parties = RecentSessionParties();
      final cis = _party("pbdf-requestors.cis");
      final vgz = _party("pbdf-requestors.vgz");
      parties.record(1, cis, completed: true);
      parties.record(2, vgz, completed: true);
      parties.record(3, cis, completed: false);

      expect(parties.recent.map((r) => r.party.id), [cis.id, vgz.id]);
      expect(parties.recent.first.completed, isFalse);
    });

    test("ignores parties without a name", () {
      final parties = RecentSessionParties();
      parties.record(1, _party("unknown", ""), completed: false);
      expect(parties.recent, isEmpty);
    });

    test("keeps only the latest sessions", () {
      final parties = RecentSessionParties();
      for (var i = 0; i < 30; i++) {
        parties.record(i, _party("party-$i"), completed: true);
      }
      expect(parties.recent, hasLength(20));
      expect(parties.recent.first.party.id, "party-29");
    });

    test(
      "the session repository records every session, finished or not",
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = IrmaRepository(
          client: _SilentBridge(),
          preferences: await IrmaPreferences.fromInstance(
            mostRecentTermsUrlNl: "",
            mostRecentTermsUrlEn: "",
          ),
        );
        addTearDown(repo.close);
        final events = StreamController<Event>();
        final sessions = SessionRepository(
          repo: repo,
          eventStream: events.stream,
        );
        addTearDown(sessions.close);
        addTearDown(events.close);

        final cis = _party("pbdf-requestors.cis", "Stichting CIS");
        final vgz = _party("pbdf-requestors.vgz", "VGZ");
        // Scanned CIS's QR code, then cancelled.
        events.add(_state(1, SessionStatus.requestPermission, cis));
        events.add(_state(1, SessionStatus.dismissed, cis));
        // Shared data with VGZ.
        events.add(_state(2, SessionStatus.requestPermission, vgz));
        events.add(_state(2, SessionStatus.success, vgz));
        await Future<void>.delayed(Duration.zero);

        final recent = sessions.recentParties.recent;
        expect(recent.map((r) => r.party.id), [vgz.id, cis.id]);
        expect(recent.map((r) => r.completed), [true, false]);
      },
    );
  });

  group("recentOrganisations", () {
    final now = DateTime(2026, 11, 13, 12);

    test("an unfinished session is offered before older activity", () {
      final cis = _party("pbdf-requestors.cis", "Stichting CIS");
      final vgz = _party("pbdf-requestors.vgz", "VGZ");
      final recent = recentOrganisations(
        sessions: [RecentSessionParty(party: cis, time: now, completed: false)],
        activity: [_disclosure(vgz, now.subtract(const Duration(days: 2)))],
      );

      expect(recent.map((r) => r.organisation.name), ["Stichting CIS", "VGZ"]);
      expect(recent.map((r) => r.unfinished), [true, false]);
    });

    test("a party in both lists appears once, as its latest", () {
      final cis = _party("pbdf-requestors.cis", "Stichting CIS");
      final recent = recentOrganisations(
        sessions: [
          RecentSessionParty(
            party: cis,
            time: now.subtract(const Duration(hours: 1)),
            completed: false,
          ),
        ],
        activity: [_disclosure(cis, now)],
      );

      expect(recent, hasLength(1));
      // Finished later on: no longer unfinished.
      expect(recent.single.unfinished, isFalse);
    });

    test("keeps Yivi's own parties, which lead to Yivi support", () {
      // A QR code on email-issuer.yivi.app starts a session with Yivi.
      final recent = recentOrganisations(
        sessions: [
          RecentSessionParty(
            party: _party("pbdf-requestors.sidn-pbdf", "Yivi"),
            time: now,
            completed: false,
          ),
        ],
        activity: const [],
      );

      expect(recent.single.organisation.name, "Yivi");
      expect(recent.single.organisation.isYivi, isTrue);
      expect(recent.single.unfinished, isTrue);
    });

    test("caps the list", () {
      final recent = recentOrganisations(
        sessions: const [],
        activity: [
          for (var i = 0; i < 8; i++)
            _disclosure(_party("org-$i"), now.subtract(Duration(days: i))),
        ],
        max: 5,
      );

      expect(recent, hasLength(5));
    });
  });
}
