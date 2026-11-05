// The screen's Yivi chrome lives under yivi_core/lib/src; the test wraps it
// the same way yivi_core's own widget tests do.
// ignore_for_file: implementation_imports
import "dart:convert";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:stream_channel/stream_channel.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi/iris_capture_screen.dart";
import "package:yivi/iris_stream_client.dart";
import "package:yivi_core/package_name.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

/// An in-memory verifier the screen connects to instead of a WebSocket.
class _FakeVerifier {
  final _controller = StreamChannelController<dynamic>();
  final sent = <dynamic>[];

  _FakeVerifier() {
    _controller.local.stream.listen(sent.add);
  }

  Future<IrisStreamClient> connect(FaceSession session) =>
      IrisStreamClient.connect(
        Uri.parse(session.streamUrl),
        token: session.token,
        connector: (_) async => _controller.foreign,
      );

  void send(Map<String, Object?> message) =>
      _controller.local.sink.add(jsonEncode(message));

  void ready() =>
      send({"type": "ready", "max_frames": 900, "max_width": 640, "fps": 15});

  Future<void> close() => _controller.local.sink.close();
}

final _session = FaceSession(
  faceSessionId: "fs-1",
  streamUrl: "wss://verifier.example/stream/fs-1",
  token: "tok",
  expiresIn: 120,
);

/// A host page with a button that pushes the capture screen, so the test
/// can observe what the route pops with.
class _Host extends StatelessWidget {
  const _Host({required this.verifier, required this.onPopped});

  final _FakeVerifier verifier;
  final void Function(IrisStreamEvent? outcome) onPopped;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const Key("open"),
        onPressed: () async {
          final outcome = await Navigator.of(context).push<IrisStreamEvent?>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => IrisCaptureScreen(
                session: _session,
                connect: verifier.connect,
              ),
            ),
          );
          onPopped(outcome);
        },
        child: const Text("open"),
      ),
    ),
  );
}

Widget _app(_FakeVerifier verifier, void Function(IrisStreamEvent?) onPopped) {
  // TestContext keeps the camera closed, as in the integration tests.
  return TestContext(
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: yiviAsset("locales"),
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: _Host(verifier: verifier, onPopped: onPopped),
      ),
    ),
  );
}

/// The screen animates its indeterminate progress forever, so pumpAndSettle
/// would never return; pump a fixed stretch instead, long enough for a route
/// transition to finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps the app, opens the screen and completes the handshake.
Future<List<IrisStreamEvent?>> _openReady(
  WidgetTester tester,
  _FakeVerifier verifier,
) async {
  final popped = <IrisStreamEvent?>[];
  await tester.pumpWidget(_app(verifier, popped.add));
  await _settle(tester);
  await tester.tap(find.byKey(const Key("open")));
  await _settle(tester);
  verifier.ready();
  await _settle(tester);
  return popped;
}

double? _progressValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byKey(const Key("iris_progress")))
    .value;

void main() {
  testWidgets("connects with the session token and shows connecting", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    await tester.pumpWidget(_app(verifier, (_) {}));
    await _settle(tester);
    await tester.tap(find.byKey(const Key("open")));
    await _settle(tester);

    expect(find.text("Face verification"), findsOneWidget);
    expect(find.text("Connecting…"), findsOneWidget);
    expect(verifier.sent, hasLength(1));
    expect(jsonDecode(verifier.sent.first as String), {
      "type": "hello",
      "token": "tok",
    });
  });

  testWidgets("after ready shows the hint and an indeterminate progress", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    await _openReady(tester, verifier);

    expect(find.text("Hold still and look at the camera"), findsOneWidget);
    expect(find.text("Connecting…"), findsNothing);
    expect(_progressValue(tester), isNull);
  });

  testWidgets("state events switch to verifying and advance the progress", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    await _openReady(tester, verifier);

    verifier.send({"type": "state", "seq": 29, "state": "initiated"});
    await _settle(tester);

    expect(find.text("Verifying…"), findsOneWidget);
    // 30 frames of a 4 s pace at 15 fps.
    expect(_progressValue(tester), closeTo(0.5, 0.001));

    verifier.send({"type": "state", "seq": 200, "state": "initiated"});
    await _settle(tester);

    expect(_progressValue(tester), 1.0);
  });

  testWidgets("pops with the result event", (tester) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    verifier.send({
      "type": "result",
      "state": "completed",
      "passed": true,
      "distance": 0.41,
    });
    await _settle(tester);

    expect(popped, hasLength(1));
    expect(
      popped.single,
      isA<IrisResultEvent>()
          .having((e) => e.completed, "completed", isTrue)
          .having((e) => e.distance, "distance", 0.41),
    );
    expect(find.byType(IrisCaptureScreen), findsNothing);
  });

  testWidgets("pops with the error event when the verifier aborts", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    verifier.send({"type": "error", "code": "timeout"});
    await _settle(tester);

    expect(
      popped.single,
      isA<IrisErrorEvent>().having((e) => e.code, "code", "timeout"),
    );
  });

  testWidgets("pops with a connection error when the socket closes early", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    await verifier.close();
    await _settle(tester);

    expect(
      popped.single,
      isA<IrisErrorEvent>().having((e) => e.code, "code", "connection_closed"),
    );
  });

  testWidgets("a refused handshake pops with a connection error", (
    tester,
  ) async {
    final verifier = _FakeVerifier();
    final popped = <IrisStreamEvent?>[];
    await tester.pumpWidget(_app(verifier, popped.add));
    await _settle(tester);
    await tester.tap(find.byKey(const Key("open")));
    await _settle(tester);

    verifier.send({"type": "error", "code": "expired"});
    await _settle(tester);

    expect(
      popped.single,
      isA<IrisErrorEvent>().having(
        (e) => e.code,
        "code",
        allOf(startsWith("connection_failed"), contains("expired")),
      ),
    );
  });

  testWidgets("the back button pops with null", (tester) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    await tester.tap(find.byKey(const Key("irma_app_bar_leading")));
    await _settle(tester);

    expect(popped, [null]);
    expect(find.byType(IrisCaptureScreen), findsNothing);
  });

  testWidgets("system back pops with null", (tester) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(popped, [null]);
  });

  testWidgets("a result after cancelling does not pop twice", (tester) async {
    final verifier = _FakeVerifier();
    final popped = await _openReady(tester, verifier);

    await tester.tap(find.byKey(const Key("irma_app_bar_leading")));
    verifier.send({"type": "result", "state": "completed"});
    await _settle(tester);

    expect(popped, [null]);
  });
}
