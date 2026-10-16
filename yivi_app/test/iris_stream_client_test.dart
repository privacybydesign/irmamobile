import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:stream_channel/stream_channel.dart";
import "package:yivi/iris_stream_client.dart";

/// An in-memory verifier: what the client sends lands in [sent], and [send]
/// delivers a message to the client.
class _FakeVerifier {
  final _controller = StreamChannelController<dynamic>();
  final sent = <dynamic>[];
  late final Future<void> clientClosed;

  _FakeVerifier() {
    final closed = Completer<void>();
    _controller.local.stream.listen(sent.add, onDone: closed.complete);
    clientClosed = closed.future;
  }

  Future<StreamChannel<dynamic>> connector(Uri _) async => _controller.foreign;

  void send(Map<String, Object?> message) =>
      _controller.local.sink.add(jsonEncode(message));

  void sendRaw(dynamic message) => _controller.local.sink.add(message);

  void ready({int maxFrames = 900, int maxWidth = 640, int fps = 15}) => send({
    "type": "ready",
    "max_frames": maxFrames,
    "max_width": maxWidth,
    "fps": fps,
  });

  Future<void> close() => _controller.local.sink.close();
}

final _url = Uri.parse("wss://verifier.example/stream/fs-1");

/// Starts the handshake and answers it with `ready`; returns the client.
Future<(IrisStreamClient, _FakeVerifier)> _connected() async {
  final verifier = _FakeVerifier();
  final connecting = IrisStreamClient.connect(
    _url,
    token: "tok",
    connector: verifier.connector,
  );
  await pumpEventQueue();
  verifier.ready();
  return (await connecting, verifier);
}

void main() {
  group("handshake", () {
    test("sends the hello with the token as the first message", () async {
      final (_, verifier) = await _connected();

      expect(verifier.sent, hasLength(1));
      expect(jsonDecode(verifier.sent.first as String), {
        "type": "hello",
        "token": "tok",
      });
    });

    test("does not put the token in the URL", () async {
      final verifier = _FakeVerifier();
      late Uri opened;
      final connecting = IrisStreamClient.connect(
        _url,
        token: "secret-token",
        connector: (url) {
          opened = url;
          return verifier.connector(url);
        },
      );
      await pumpEventQueue();
      verifier.ready();
      await connecting;

      expect(opened, _url);
      expect(opened.toString(), isNot(contains("secret-token")));
    });

    test("parses the ready limits", () async {
      final verifier = _FakeVerifier();
      final connecting = IrisStreamClient.connect(
        _url,
        token: "tok",
        connector: verifier.connector,
      );
      await pumpEventQueue();
      verifier.ready(maxFrames: 450, maxWidth: 320, fps: 10);
      final client = await connecting;

      expect(client.limits.maxFrames, 450);
      expect(client.limits.maxWidth, 320);
      expect(client.limits.fps, 10);
    });

    test("an error before ready throws with its code and closes", () async {
      final verifier = _FakeVerifier();
      final connecting = IrisStreamClient.connect(
        _url,
        token: "tok",
        connector: verifier.connector,
      );
      await pumpEventQueue();
      verifier.send({"type": "error", "code": "unauthorized"});

      await expectLater(
        connecting,
        throwsA(
          isA<IrisStreamException>().having(
            (e) => e.code,
            "code",
            "unauthorized",
          ),
        ),
      );
      await expectLater(verifier.clientClosed, completes);
    });

    test("a close before ready throws", () async {
      final verifier = _FakeVerifier();
      final connecting = IrisStreamClient.connect(
        _url,
        token: "tok",
        connector: verifier.connector,
      );
      await pumpEventQueue();
      await verifier.close();

      await expectLater(
        connecting,
        throwsA(
          isA<IrisStreamException>().having(
            (e) => e.code,
            "code",
            "closed_before_ready",
          ),
        ),
      );
    });
  });

  group("events", () {
    test("state, result and error messages are parsed in order", () async {
      final (client, verifier) = await _connected();
      final events = <IrisStreamEvent>[];
      final done = client.events.listen(events.add).asFuture<void>();

      verifier.send({"type": "state", "seq": 7, "state": "initiated"});
      verifier.send({
        "type": "result",
        "state": "completed",
        "passed": true,
        "distance": 0.41,
      });
      verifier.send({"type": "error", "code": "timeout"});
      await verifier.close();
      await done;

      expect(events, hasLength(3));
      expect(
        events[0],
        isA<IrisStateEvent>()
            .having((e) => e.seq, "seq", 7)
            .having((e) => e.state, "state", "initiated"),
      );
      expect(
        events[1],
        isA<IrisResultEvent>()
            .having((e) => e.completed, "completed", isTrue)
            .having((e) => e.passed, "passed", isTrue)
            .having((e) => e.distance, "distance", 0.41),
      );
      expect(
        events[2],
        isA<IrisErrorEvent>().having((e) => e.code, "code", "timeout"),
      );
    });

    test("a failed result carries no verdict fields", () async {
      final (client, verifier) = await _connected();
      final first = client.events.first;

      verifier.send({"type": "result", "state": "failed"});

      final event = await first as IrisResultEvent;
      expect(event.completed, isFalse);
      expect(event.passed, isNull);
      expect(event.distance, isNull);
    });

    test("a message right after ready is not lost", () async {
      final verifier = _FakeVerifier();
      final connecting = IrisStreamClient.connect(
        _url,
        token: "tok",
        connector: verifier.connector,
      );
      await pumpEventQueue();
      verifier.ready();
      verifier.send({"type": "state", "seq": 0, "state": "initiated"});
      final client = await connecting;

      expect(await client.events.first, isA<IrisStateEvent>());
    });

    test("binary, malformed and unknown messages are ignored", () async {
      final (client, verifier) = await _connected();
      final events = <IrisStreamEvent>[];
      final done = client.events.listen(events.add).asFuture<void>();

      verifier.sendRaw(Uint8List.fromList([1, 2, 3]));
      verifier.sendRaw("not json");
      verifier.send({"type": "ping"});
      verifier.send({"type": "state", "seq": 1, "state": "initiated"});
      await verifier.close();
      await done;

      expect(events, hasLength(1));
    });

    test("the stream ends when the verifier closes", () async {
      final (client, verifier) = await _connected();
      final done = client.events.toList();

      await verifier.close();

      expect(await done, isEmpty);
    });
  });

  group("frames", () {
    test("the header is 16 little-endian bytes followed by the JPEG", () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
      final message = IrisStreamClient.encodeFrameMessage(
        jpeg,
        seq: 0x01020304,
        tsMs: 0x0A0B0C0D,
        width: 640,
        height: 480,
        orientation: 3,
      );

      expect(message.length, irisFrameHeaderLength + jpeg.length);
      expect(message.sublist(0, 4), [0x04, 0x03, 0x02, 0x01]); // seq
      expect(message.sublist(4, 8), [0x0D, 0x0C, 0x0B, 0x0A]); // ts_ms
      expect(message.sublist(8, 10), [0x80, 0x02]); // width 640
      expect(message.sublist(10, 12), [0xE0, 0x01]); // height 480
      expect(message[12], 3); // orientation
      expect(message.sublist(13, 16), [0, 0, 0]); // reserved
      expect(message.sublist(16), jpeg);
    });

    test("sendFrame puts the frame on the socket as binary", () async {
      final (client, verifier) = await _connected();
      final jpeg = Uint8List.fromList([0xFF, 0xD8]);

      client.sendFrame(
        jpeg,
        seq: 1,
        tsMs: 66,
        width: 320,
        height: 240,
        orientation: 1,
      );
      await pumpEventQueue();

      expect(verifier.sent, hasLength(2)); // hello + frame
      final frame = verifier.sent[1] as Uint8List;
      expect(
        frame,
        IrisStreamClient.encodeFrameMessage(
          jpeg,
          seq: 1,
          tsMs: 66,
          width: 320,
          height: 240,
          orientation: 1,
        ),
      );
    });

    test("close ends the socket and drops later frames", () async {
      final (client, verifier) = await _connected();

      await client.close();
      await client.close(); // idempotent
      client.sendFrame(
        Uint8List(0),
        seq: 0,
        tsMs: 0,
        width: 1,
        height: 1,
        orientation: 0,
      );

      await expectLater(verifier.clientClosed, completes);
      expect(verifier.sent, hasLength(1)); // only the hello
    });
  });
}
