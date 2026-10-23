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
import "package:yivi_core/src/screens/pin/widgets/waiting_request_announcement.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";

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

/// The announcement and the key of the line under it, for what waits.
class _Waiting extends ConsumerWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(waitingRequestProvider).value;
    if (waiting == null) return const Text("nothing waits");
    return Column(
      children: [
        WaitingRequestAnnouncement(request: waiting),
        Text(waitingLineKey(waiting), key: const Key("line")),
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

  String sentence(WidgetTester tester) =>
      text(tester, "waiting_request_sentence");

  /// No trust line and no host on the screen: just the sentence.
  void onlyTheSentence(WidgetTester tester, {String? host}) {
    expect(find.byKey(const Key("waiting_request_pill")), findsNothing);
    if (host != null) expect(find.textContaining(host), findsNothing);
  }

  testWidgets("a registered requestor: who and what, in one sentence", (
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
    expect(sentence(tester), "Webshop Noord is offering data");
    expect(
      find.byKey(const ValueKey(("waiting_request_badge", "add"))),
      findsOneWidget,
    );
    expect(text(tester, "line"), "waiting_request.line.see");
    onlyTheSentence(tester, host: "shop.example.com");
    // Asked once, for this pointer.
    final asked = bridge.dispatched.whereType<PreviewSessionEvent>().toList();
    expect(asked, hasLength(1));
    expect(asked.single.key, "https://shop.example.com/irma/session/abc");
  });

  testWidgets("not in the scheme: its host as the name, no trust line", (
    tester,
  ) async {
    answer(
      SessionPreview(
        kind: SessionPreviewKind.disclosure,
        knowledge: SessionPreviewKnowledge.unregistered,
        host: "shop.example.com",
        requestor: _party("shop.example.com", verified: false),
      ),
    );
    await pump(tester, _pointer("disclosing"));
    expect(sentence(tester), "shop.example.com is asking for data");
    expect(text(tester, "line"), "waiting_request.line.see");
    onlyTheSentence(tester);
  });

  testWidgets("OpenID4VP: generic, without the host", (tester) async {
    answer(
      const SessionPreview(
        kind: SessionPreviewKind.disclosure,
        knowledge: SessionPreviewKnowledge.host,
        host: "verifier.example.eu",
      ),
    );
    await pump(tester, _pointer("disclosing", protocol: Protocol.openid4vp));
    expect(sentence(tester), "A request for data is waiting");
    expect(find.byKey(const Key("waiting_request_generic")), findsOneWidget);
    expect(text(tester, "line"), "waiting_request.line.who");
    onlyTheSentence(tester, host: "verifier.example.eu");
  });

  testWidgets("OpenID4VCI: generic, without the host", (tester) async {
    answer(
      const SessionPreview(
        kind: SessionPreviewKind.issuance,
        knowledge: SessionPreviewKnowledge.host,
        host: "issuer.example.eu",
      ),
    );
    await pump(tester, _pointer("issuing", protocol: Protocol.openid4vci));
    expect(sentence(tester), "Data is being offered");
    expect(text(tester, "line"), "waiting_request.line.who");
    onlyTheSentence(tester, host: "issuer.example.eu");
  });

  testWidgets("before irmago answers: the kind the pointer says", (
    tester,
  ) async {
    await pump(tester, _pointer("signing"));
    expect(sentence(tester), "A request for a signature is waiting");
    expect(text(tester, "line"), "waiting_request.line.who");
  });

  testWidgets("a redirect pointer: that a request waits", (tester) async {
    answer(SessionPreview.unknown);
    await pump(tester, _pointer("redirect"));
    expect(sentence(tester), "A request is waiting");
    expect(text(tester, "line"), "waiting_request.line.who");
  });

  testWidgets("the link in an email: what it adds, not the address", (
    tester,
  ) async {
    await pump(
      tester,
      EmailCodePointer(email: "sanne@devries.example", code: "ABC123"),
    );
    expect(sentence(tester), "Add your email address to Yivi");
    expect(text(tester, "line"), "waiting_request.line.see");
    expect(find.text("sanne@devries.example"), findsNothing);
  });

  testWidgets("a request already going: whose, and to go on", (tester) async {
    await pumpHome(
      tester,
      repo: repo,
      home: Builder(
        builder: (context) {
          final waiting = WaitingRequest(
            inFlight: true,
            preview: SessionPreview(
              kind: SessionPreviewKind.disclosure,
              knowledge: SessionPreviewKnowledge.registered,
              requestor: _party("Webshop Noord", verified: true),
            ),
          );
          return Column(
            children: [
              WaitingRequestAnnouncement(request: waiting),
              Text(waitingLineKey(waiting), key: const Key("line")),
            ],
          );
        },
      ),
    );
    expect(
      sentence(tester),
      "You were in the middle of a request from Webshop Noord",
    );
    expect(text(tester, "line"), "waiting_request.line.continue");
  });

  group("on the PIN screen", () {
    final waiting = WaitingRequest(
      preview: SessionPreview(
        kind: SessionPreviewKind.disclosure,
        knowledge: SessionPreviewKnowledge.registered,
        requestor: _party("Webshop Noord", verified: true),
      ),
    );

    /// The PIN screen with the announcement, as the lock screen ([sheet]
    /// false) or the scanner sheet's page draws it, in a window of [size].
    Future<void> pin(
      WidgetTester tester,
      Size size, {
      bool sheet = false,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        repo: repo,
        home: YiviPinScreen(
          header: WaitingRequestAnnouncement(request: waiting),
          showMark: false,
          instruction: "Enter your PIN to see it",
          instructionStyle: PinInstructionStyle.line,
          upperGap: 48,
          centreUpper: sheet,
          maxPinSize: 5,
          onSubmit: (_) {},
        ),
      );
    }

    Rect key(WidgetTester tester, int n) =>
        tester.getRect(find.byKey(Key("number_pad_key_$n")));
    Rect sentenceRect(WidgetTester tester) =>
        tester.getRect(find.byKey(const Key("waiting_request_sentence")));
    Rect line(WidgetTester tester) =>
        tester.getRect(find.text("Enter your PIN to see it"));

    testWidgets("upright: two lines, the block 48 or more above the keypad", (
      tester,
    ) async {
      await pin(tester, const Size(390, 844));
      // Only the sentence and the line between the avatar and the dots.
      expect(find.byKey(const Key("pin_screen_detail")), findsNothing);
      expect(line(tester).top, greaterThan(sentenceRect(tester).bottom));
      expect(key(tester, 1).top - line(tester).bottom, greaterThan(48));
    });

    testWidgets("in the sheet: in the middle of the room above the keypad", (
      tester,
    ) async {
      await pin(tester, const Size(390, 782), sheet: true);
      final block = tester.getRect(
        find.byKey(const Key("waiting_request_announcement")),
      );
      final room = key(tester, 1).top - 48;
      // The block (announcement to dots) has as much room above as below.
      final above = block.top;
      expect(above, greaterThan(40));
      expect(block.top, lessThan(room / 2));
    });

    testWidgets("sideways: a centred column in the left half", (tester) async {
      await pin(tester, const Size(874, 402));
      final sentence = sentenceRect(tester);
      final half = 874 / 2;
      expect(sentence.center.dx, closeTo(half / 2, 24));
      expect(line(tester).center.dx, closeTo(sentence.center.dx, 2));
      expect(key(tester, 1).left, greaterThan(half));
    });
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
