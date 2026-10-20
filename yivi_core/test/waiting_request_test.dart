import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_preview.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/waiting_request_provider.dart";
import "package:yivi_core/src/screens/pin/widgets/waiting_request_card.dart";

import "support/onboarding_v2_harness.dart";

SessionPointer _pointer(String irmaqr, {Protocol protocol = Protocol.irma}) =>
    SessionPointer(
      u: "https://shop.example.com/irma/session/abc",
      irmaqr: irmaqr,
      protocol: protocol,
    );

TrustedParty _party(String name, {required bool verified}) => TrustedParty(
  id: name,
  name: name,
  url: null,
  parent: null,
  verified: verified,
);

/// The card and the line under the heading, for what waits.
class _Waiting extends ConsumerWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(waitingRequestProvider).value;
    if (waiting == null) return const Text("nothing waits");
    return Column(
      children: [
        WaitingRequestCard(request: waiting),
        Text(waitingHeadKey(waiting), key: const Key("head")),
        Text(waitingDetail(context, waiting) ?? "", key: const Key("detail")),
      ],
    );
  }
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

  /// irmago answers every preview with [preview].
  void answer(SessionPreview preview) =>
      bridge.respond = (Event event) => event is PreviewSessionEvent
      ? SessionPreviewEvent(key: event.key, preview: preview)
      : null;

  Future<void> pump(WidgetTester tester, Pointer? pointer) async {
    await pumpHome(
      tester,
      repo: repo,
      home: const _Waiting(),
      overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
    );
    repo.setPendingPointer(pointer);
    // irmago's answer comes back on the real event loop.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data ?? "";

  testWidgets("a registered requestor: its name, what it wants, the check", (
    tester,
  ) async {
    answer(
      SessionPreview(
        kind: SessionPreviewKind.issuance,
        knowledge: SessionPreviewKnowledge.registered,
        host: "shop.example.com",
        requestor: _party("Webshop Noord", verified: true),
      ),
    );
    await pump(tester, _pointer("issuing"));
    expect(find.text("Webshop Noord"), findsOneWidget);
    expect(find.text("is offering data"), findsOneWidget);
    expect(find.text("Registered with Yivi"), findsOneWidget);
    expect(
      find.byKey(const ValueKey(("waiting_request_badge", "add"))),
      findsOneWidget,
    );
    expect(text(tester, "head"), "waiting_request.head");
    expect(text(tester, "detail"), "");
    // Asked once, for this pointer.
    final asked = bridge.dispatched.whereType<PreviewSessionEvent>().toList();
    expect(asked, hasLength(1));
    expect(asked.single.key, "https://shop.example.com/irma/session/abc");
  });

  testWidgets("not in the scheme: the host, said plainly", (tester) async {
    answer(
      SessionPreview(
        kind: SessionPreviewKind.disclosure,
        knowledge: SessionPreviewKnowledge.unregistered,
        host: "shop.example.com",
        requestor: _party("shop.example.com", verified: false),
      ),
    );
    await pump(tester, _pointer("disclosing"));
    expect(find.text("shop.example.com"), findsOneWidget);
    expect(find.text("is asking for data"), findsOneWidget);
    expect(find.text("Not known by Yivi"), findsOneWidget);
  });

  testWidgets("OpenID4VP: only the website, and what comes next", (
    tester,
  ) async {
    answer(
      const SessionPreview(
        kind: SessionPreviewKind.disclosure,
        knowledge: SessionPreviewKnowledge.host,
        host: "verifier.example.eu",
      ),
    );
    await pump(tester, _pointer("disclosing", protocol: Protocol.openid4vp));
    expect(find.text("verifier.example.eu"), findsOneWidget);
    expect(find.text("Website"), findsOneWidget);
    expect(
      text(tester, "detail"),
      "Next you see who they are and what they ask",
    );
  });

  testWidgets("before irmago answers: what the pointer says", (tester) async {
    await pump(tester, _pointer("signing"));
    expect(find.text("A request is waiting"), findsOneWidget);
    expect(find.text("is asking for a signature"), findsOneWidget);
    expect(
      text(tester, "detail"),
      "Next you see who it is from and what they ask",
    );
  });

  testWidgets("a redirect pointer: nothing known yet", (tester) async {
    answer(SessionPreview.unknown);
    await pump(tester, _pointer("redirect"));
    expect(find.text("A request is waiting"), findsOneWidget);
    expect(find.text("is asking for data"), findsNothing);
    expect(text(tester, "head"), "waiting_request.head_unknown");
  });

  testWidgets("the link in an email: the address it adds", (tester) async {
    await pump(
      tester,
      EmailCodePointer(email: "sanne@devries.example", code: "ABC123"),
    );
    expect(find.text("sanne@devries.example"), findsOneWidget);
    expect(find.text("Add this email address to Yivi"), findsOneWidget);
    expect(text(tester, "head"), "waiting_request.head_email");
    expect(text(tester, "detail"), "You opened the link in your email");
  });

  testWidgets("nothing waits", (tester) async {
    await pump(tester, null);
    expect(find.text("nothing waits"), findsOneWidget);
  });

  test("a preview from irmago's JSON", () {
    final preview = SessionPreview.fromJson({
      "kind": "issuance",
      "protocol": "irma",
      "knowledge": "registered",
      "host": "shop.example.com",
      "requestor": {
        "id": "pbdf-requestors.webshop",
        "name": "Webshop Noord",
        "url": null,
        "parent": null,
        "verified": true,
      },
    });
    expect(preview.kind, SessionPreviewKind.issuance);
    expect(preview.knowledge, SessionPreviewKnowledge.registered);
    expect(preview.requestor?.name, "Webshop Noord");
    // Unknown values: the cautious reading.
    final odd = SessionPreview.fromJson({"kind": "x", "knowledge": "y"});
    expect(odd.kind, SessionPreviewKind.unknown);
    expect(odd.knowledge, SessionPreviewKnowledge.none);
  });
}
