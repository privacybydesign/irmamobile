import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/demo_session_requests.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";

TrustedParty _party(String name, {bool verified = false}) => TrustedParty(
  id: "",
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

SessionState _session(TrustedParty requestor) => SessionState(
  id: 7,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: requestor,
  clientReturnUrl: "https://example.com/back",
  continueOnSecondDevice: true,
);

void main() {
  test("the demo server becomes a party Yivi knows", () {
    final state = trustDemoServer(_session(_party(demoServerHost)));

    expect(state.requestor.verified, isTrue);
    expect(state.requestor.name, "Yivi demo");
    expect(state.id, 7);
    expect(state.type, SessionType.disclosure);
    expect(state.status, SessionStatus.requestPermission);
    expect(state.clientReturnUrl, "https://example.com/back");
    expect(state.continueOnSecondDevice, isTrue);
  });

  test("other requestors stay as they are", () {
    final unknown = _session(_party("other.example"));
    final known = _session(_party(demoServerHost, verified: true));

    expect(trustDemoServer(unknown), same(unknown));
    expect(trustDemoServer(known), same(known));
  });
}
