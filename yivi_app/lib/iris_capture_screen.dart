// yivi_core exposes its theme, shared widgets and camera permission helper
// only under lib/src (no public barrel), so the Yivi chrome here must import
// them by their src path.
// ignore_for_file: implementation_imports
import "dart:async";
import "dart:io";

import "package:camera/camera.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/screens/scanner/util/handle_camera_permission.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/loading_indicator.dart";
import "package:yivi_core/src/widgets/translated_text.dart";

import "iris_frame.dart";
import "iris_stream_client.dart";

/// Opens the verifier stream for [session]. Injected so tests run the screen
/// against an in-memory channel.
typedef IrisConnect = Future<IrisStreamClient> Function(FaceSession session);

Future<IrisStreamClient> _connectToSession(FaceSession session) =>
    IrisStreamClient.connect(
      Uri.parse(session.streamUrl),
      token: session.token,
    );

/// Full-screen route that streams front-camera frames to the Iris verifier
/// for one face session and resolves with the verifier's answer.
///
/// The route pops with:
/// - the [IrisResultEvent] (`completed` or `failed`) the verifier ended the
///   stream with;
/// - an [IrisErrorEvent] when the verifier aborted the stream, the socket
///   failed, or the camera could not be used (`camera_permission_denied`,
///   `camera_unavailable`, `connection_failed`, `connection_closed`);
/// - `null` when the user backed out.
///
/// The verdict is not shown here: the issuer pulls it at issuance, so the
/// screen only reports progress. Under an integration test
/// ([TestContext]) the camera is left closed and only the stream runs.
class IrisCaptureScreen extends StatefulWidget {
  const IrisCaptureScreen({
    super.key,
    required this.session,
    this.connect = _connectToSession,
  });

  final FaceSession session;
  final IrisConnect connect;

  @override
  State<IrisCaptureScreen> createState() => _IrisCaptureScreenState();
}

enum _Phase { connecting, streaming, verifying }

class _IrisCaptureScreenState extends State<IrisCaptureScreen> {
  IrisStreamClient? _client;
  StreamSubscription<IrisStreamEvent>? _events;
  CameraController? _camera;
  CameraDescription? _cameraDescription;

  _Phase _phase = _Phase.connecting;
  double? _progress;

  /// Guards against resolving the route more than once (a result arriving as
  /// the user taps back).
  bool _resolved = false;

  /// One frame is encoded at a time; frames arriving meanwhile are skipped,
  /// never queued, so a slow device falls behind in rate rather than latency.
  bool _encoding = false;
  int _seq = 0;
  int _lastFrameMs = -1;
  final _frameClock = Stopwatch();

  /// Frames (at the negotiated rate) that fill the progress bar. A pacing
  /// aid so the bar moves while the verifier works, not an estimate of its
  /// decision; tune once real captures have been measured.
  static const _paceSeconds = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    unawaited(_client?.close());
    unawaited(_stopCamera(_camera));
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    final testMode = TestContext.isRunningIntegrationTest(context);
    if (!testMode && !await handleCameraPermission(context)) {
      _finish(const IrisErrorEvent("camera_permission_denied"));
      return;
    }
    if (!mounted) return;

    final IrisStreamClient client;
    try {
      client = await widget.connect(widget.session);
    } catch (e) {
      _finish(IrisErrorEvent("connection_failed: $e"));
      return;
    }
    if (!mounted) {
      await client.close();
      return;
    }
    _client = client;
    _events = client.events.listen(
      _onEvent,
      onError: (Object e) => _finish(IrisErrorEvent("connection_failed: $e")),
      // The verifier closes after its terminal message, which _onEvent has
      // handled by then; a close without one is a failure.
      onDone: () => _finish(const IrisErrorEvent("connection_closed")),
    );
    setState(() => _phase = _Phase.streaming);

    if (!testMode) await _startCamera(client.limits);
  }

  void _onEvent(IrisStreamEvent event) {
    switch (event) {
      case IrisStateEvent(:final seq):
        final paceFrames = (_client?.limits.fps ?? 15) * _paceSeconds;
        setState(() {
          _phase = _Phase.verifying;
          _progress = ((seq + 1) / paceFrames).clamp(0.0, 1.0);
        });
      case IrisResultEvent() || IrisErrorEvent():
        _finish(event);
    }
  }

  void _finish(IrisStreamEvent? outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _startCamera(IrisStreamLimits limits) async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        // 1280x720 on Android; frames are downscaled to the verifier's
        // max_width, so it decides the resolution the engine sees.
        ResolutionPreset.high,
        enableAudio: false,
        // The plugin's native formats per platform; iris_frame converts both.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted || _resolved) {
        await controller.dispose();
        return;
      }
      _cameraDescription = camera;
      setState(() => _camera = controller);
      await controller.startImageStream((image) => _onFrame(image, limits));
    } catch (e) {
      _finish(IrisErrorEvent("camera_unavailable: $e"));
    }
  }

  Future<void> _stopCamera(CameraController? camera) async {
    if (camera == null) return;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } catch (e) {
      debugPrint("iris: failed to stop image stream: $e");
    }
    await camera.dispose();
  }

  void _onFrame(CameraImage image, IrisStreamLimits limits) {
    final client = _client;
    final camera = _camera;
    final description = _cameraDescription;
    if (client == null || camera == null || description == null) return;
    if (_resolved || _encoding || _seq >= limits.maxFrames) return;

    if (!_frameClock.isRunning) _frameClock.start();
    final nowMs = _frameClock.elapsedMilliseconds;
    // Throttle to the verifier's cadence; it drops faster frames anyway.
    if (_lastFrameMs >= 0 && nowMs - _lastFrameMs < 1000 ~/ limits.fps) return;
    _lastFrameMs = nowMs;

    _encoding = true;
    final frame = RawFrame.fromCameraImage(image);
    final size = scaledFrameSize(image.width, image.height, limits.maxWidth);
    final orientation = frameOrientation(
      sensorOrientation: description.sensorOrientation,
      deviceOrientation: camera.value.deviceOrientation,
      frontCamera: description.lensDirection == CameraLensDirection.front,
      isIOS: Platform.isIOS,
    );
    unawaited(
      _encodeAndSend(
        frame,
        limits: limits,
        tsMs: nowMs,
        width: size.width,
        height: size.height,
        orientation: orientation,
      ),
    );
  }

  Future<void> _encodeAndSend(
    RawFrame frame, {
    required IrisStreamLimits limits,
    required int tsMs,
    required int width,
    required int height,
    required int orientation,
  }) async {
    try {
      final jpeg = await encodeFrameJpeg(frame, maxLongSide: limits.maxWidth);
      if (_resolved || !mounted) return;
      _client?.sendFrame(
        jpeg,
        seq: _seq++,
        tsMs: tsMs,
        width: width,
        height: height,
        orientation: orientation,
      );
    } catch (e) {
      // One bad frame is not fatal; the next one is tried.
      debugPrint("iris: frame encode failed: $e");
    } finally {
      _encoding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return PopScope(
      // Hardware/gesture back resolves as a cancel, which the runner turns
      // into a throw, matching the Regula capture.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(null);
      },
      child: Scaffold(
        backgroundColor: theme.light,
        appBar: IrmaAppBar(
          titleTranslationKey: "face_verification.title",
          leading: YiviBackButton(onTap: () => _finish(null)),
        ),
        body: Column(
          children: [
            Expanded(child: _preview(theme)),
            Padding(
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: Column(
                children: [
                  TranslatedText(
                    switch (_phase) {
                      _Phase.connecting => "face_verification.iris.connecting",
                      _Phase.streaming => "face_verification.iris.hint",
                      _Phase.verifying => "face_verification.iris.verifying",
                    },
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: theme.defaultSpacing),
                  LinearProgressIndicator(
                    key: const Key("iris_progress"),
                    value: _progress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(IrmaThemeData theme) {
    final camera = _camera;
    final previewSize = camera?.value.previewSize;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && previewSize != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                // The plugin reports the preview size landscape; the app is
                // portrait-only, so swap the sides to cover the box.
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(camera),
              ),
            )
          else
            ColoredBox(color: theme.dark),
          CustomPaint(
            painter: _FaceOvalPainter(
              scrim: theme.dark.withValues(alpha: 0.55),
              stroke: _phase == _Phase.verifying ? theme.primary : theme.light,
            ),
          ),
          if (_phase == _Phase.connecting) Center(child: LoadingIndicator()),
        ],
      ),
    );
  }
}

/// Darkens everything outside a face-sized oval and strokes its edge.
class _FaceOvalPainter extends CustomPainter {
  const _FaceOvalPainter({required this.scrim, required this.stroke});

  final Color scrim;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.7;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: ovalWidth,
      height: ovalWidth * 1.35,
    );
    // Cut the oval out of the scrim as geometry rather than with a clear
    // blend mode, which needs a saveLayer over a camera texture.
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(oval),
    );
    canvas.drawPath(outside, Paint()..color = scrim);
    canvas.drawOval(
      oval,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_FaceOvalPainter old) =>
      old.scrim != scrim || old.stroke != stroke;
}
