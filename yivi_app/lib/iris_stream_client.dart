import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:stream_channel/stream_channel.dart";
import "package:web_socket_channel/web_socket_channel.dart";

/// What the verifier allows for this session, from its `ready` message.
class IrisStreamLimits {
  const IrisStreamLimits({
    required this.maxFrames,
    required this.maxWidth,
    required this.fps,
  });

  /// Frames the verifier processes at most before it errors.
  final int maxFrames;

  /// Longest side of a frame in pixels; larger frames are rejected.
  final int maxWidth;

  /// Frames per second the verifier accepts; faster ones are dropped.
  final int fps;

  factory IrisStreamLimits.fromJson(Map<String, dynamic> json) =>
      IrisStreamLimits(
        maxFrames: (json["max_frames"] as num).toInt(),
        maxWidth: (json["max_width"] as num).toInt(),
        fps: (json["fps"] as num).toInt(),
      );
}

/// A message from the verifier after the stream is established.
sealed class IrisStreamEvent {
  const IrisStreamEvent();
}

/// Progress: the verifier processed frame [seq] and is in library state
/// [state] (e.g. `initiated`).
final class IrisStateEvent extends IrisStreamEvent {
  const IrisStateEvent({required this.seq, required this.state});

  final int seq;
  final String state;
}

/// The terminal verdict of the stream. [state] is `completed` or `failed`;
/// [passed] and [distance] are only present on `completed`. The wallet does
/// not act on [passed]: the issuer pulls the same verdict at issuance.
final class IrisResultEvent extends IrisStreamEvent {
  const IrisResultEvent({required this.state, this.passed, this.distance});

  final String state;
  final bool? passed;
  final double? distance;

  bool get completed => state == "completed";
}

/// The verifier gave up on the stream (`timeout`, `too_many_frames`,
/// `frame_too_large`, `bad_frame`) or the socket itself failed.
final class IrisErrorEvent extends IrisStreamEvent {
  const IrisErrorEvent(this.code);

  final String code;
}

/// The verifier refused the session before it became ready
/// (`unauthorized`, `expired`, `already_streaming`), or closed without
/// answering the hello.
class IrisStreamException implements Exception {
  IrisStreamException(this.code);

  final String code;

  @override
  String toString() => "IrisStreamException: $code";
}

/// Opens the transport for [url]. The default opens a WebSocket; tests hand
/// in an in-memory [StreamChannel] instead.
typedef IrisChannelConnector = Future<StreamChannel<dynamic>> Function(Uri url);

Future<StreamChannel<dynamic>> _connectWebSocket(Uri url) async {
  final channel = WebSocketChannel.connect(url);
  // Surface a refused connection here instead of as an error on the stream.
  await channel.ready;
  return channel;
}

/// Size of the binary header that precedes every JPEG frame.
const irisFrameHeaderLength = 16;

/// The wallet side of the verifier's stream protocol
/// (`wss://<verifier>/stream/{face_session_id}`).
///
/// [connect] performs the handshake: it sends the hello with the session
/// token as the first text message (never in the URL, so it is not logged by
/// ingress) and waits for the verifier's `ready`. After that the caller pushes
/// frames with [sendFrame] and reads the verifier's answers from [events],
/// which ends with one [IrisResultEvent] or [IrisErrorEvent].
class IrisStreamClient {
  IrisStreamClient._(
    this._channel,
    this._subscription,
    this._events,
    this.limits,
  );

  final StreamChannel<dynamic> _channel;
  final StreamSubscription<dynamic> _subscription;
  final StreamController<IrisStreamEvent> _events;
  bool _closed = false;

  /// The limits the verifier announced in its `ready` message.
  final IrisStreamLimits limits;

  /// State, result and error messages, in order. Ends after the terminal
  /// message or when the socket closes; a transport failure is a stream
  /// error.
  Stream<IrisStreamEvent> get events => _events.stream;

  static Future<IrisStreamClient> connect(
    Uri streamUrl, {
    required String token,
    IrisChannelConnector connector = _connectWebSocket,
  }) async {
    final channel = await connector(streamUrl);
    channel.sink.add(jsonEncode({"type": "hello", "token": token}));

    // The first message settles the handshake; everything after it goes to
    // the event controller, so one subscription serves both phases. The
    // controller exists before the client so a message that follows `ready`
    // immediately is buffered rather than lost.
    final ready = Completer<IrisStreamLimits>();
    final events = StreamController<IrisStreamEvent>();
    final subscription = channel.stream.listen(
      (raw) {
        final message = _decode(raw);
        if (message == null) return;
        if (!ready.isCompleted) {
          _settleHandshake(message, ready);
        } else {
          final event = _parseEvent(message);
          if (event != null) events.add(event);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!ready.isCompleted) {
          ready.completeError(error, stack);
        } else {
          events.addError(error, stack);
        }
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(IrisStreamException("closed_before_ready"));
        }
        unawaited(events.close());
      },
    );

    try {
      final limits = await ready.future;
      return IrisStreamClient._(channel, subscription, events, limits);
    } catch (_) {
      // The cancel is not awaited: its future comes from the root zone, so
      // awaiting it stalls under a fake-async test clock. Nor is the
      // controller's close: one nobody listens to never reports done.
      unawaited(subscription.cancel());
      await channel.sink.close();
      unawaited(events.close());
      rethrow;
    }
  }

  static void _settleHandshake(
    Map<String, dynamic> message,
    Completer<IrisStreamLimits> ready,
  ) {
    switch (message["type"]) {
      case "ready":
        ready.complete(IrisStreamLimits.fromJson(message));
      case "error":
        ready.completeError(IrisStreamException("${message["code"]}"));
      case final other:
        ready.completeError(
          IrisStreamException("unexpected_before_ready: $other"),
        );
    }
  }

  /// Text messages carry JSON objects; anything else (binary, malformed) is
  /// not part of the protocol and is ignored rather than fatal.
  static Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static IrisStreamEvent? _parseEvent(Map<String, dynamic> message) =>
      switch (message["type"]) {
        "state" => IrisStateEvent(
          seq: (message["seq"] as num?)?.toInt() ?? 0,
          state: "${message["state"]}",
        ),
        "result" => IrisResultEvent(
          state: "${message["state"]}",
          passed: message["passed"] as bool?,
          distance: (message["distance"] as num?)?.toDouble(),
        ),
        "error" => IrisErrorEvent("${message["code"]}"),
        _ => null,
      };

  /// Sends one JPEG frame with its header. [tsMs] counts from the first frame
  /// sent; [orientation] is the rotation enum 0–3 (0 = none, 1 = 90°,
  /// 2 = 180°, 3 = 270°).
  void sendFrame(
    Uint8List jpeg, {
    required int seq,
    required int tsMs,
    required int width,
    required int height,
    required int orientation,
  }) {
    if (_closed) return;
    _channel.sink.add(
      encodeFrameMessage(
        jpeg,
        seq: seq,
        tsMs: tsMs,
        width: width,
        height: height,
        orientation: orientation,
      ),
    );
  }

  /// The binary frame message: a 16-byte little-endian header (`seq` u32,
  /// `ts_ms` u32, `width` u16, `height` u16, `orientation` u8, 3 reserved)
  /// followed by the JPEG bytes.
  static Uint8List encodeFrameMessage(
    Uint8List jpeg, {
    required int seq,
    required int tsMs,
    required int width,
    required int height,
    required int orientation,
  }) {
    final message = Uint8List(irisFrameHeaderLength + jpeg.length);
    ByteData.sublistView(message, 0, irisFrameHeaderLength)
      ..setUint32(0, seq, Endian.little)
      ..setUint32(4, tsMs, Endian.little)
      ..setUint16(8, width, Endian.little)
      ..setUint16(10, height, Endian.little)
      ..setUint8(12, orientation);
    // Bytes 13–15 are reserved and stay zero.
    message.setRange(irisFrameHeaderLength, message.length, jpeg);
    return message;
  }

  /// Closes the socket and ends [events]. Safe to call more than once.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Same reasons as in [connect] for not awaiting these two.
    unawaited(_subscription.cancel());
    await _channel.sink.close();
    if (!_events.isClosed) unawaited(_events.close());
  }
}
