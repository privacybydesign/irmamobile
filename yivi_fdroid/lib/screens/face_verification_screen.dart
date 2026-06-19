import "dart:async";
import "dart:io" show Platform;
import "dart:math" as math;

import "package:camera/camera.dart";
import "package:face_verification/face_verification.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:yivi_core/yivi_core.dart";

// ── Enums & helpers ────────────────────────────────────────────────────────

enum VerificationState { idle, verifying, processing, result, failed }

class _PassiveProgress {
  const _PassiveProgress({required this.started, required this.elapsedMs, required this.targetMs});

  final bool started;
  final int elapsedMs;
  final int targetMs;
}

double faceMatchThreshold(DateTime? photoIssueDate) {
  if (photoIssueDate == null) return 0.60;
  final ageYears = DateTime.now().difference(photoIssueDate).inDays / 365.25;
  if (ageYears <= 3) return 0.65;
  if (ageYears <= 7) return 0.60;
  return 0.55;
}

// ── Result model ───────────────────────────────────────────────────────────

class VerificationResult {
  const VerificationResult({required this.matchScore, required this.isLive});

  final double matchScore;
  final bool isLive;
}

// ── Widget ─────────────────────────────────────────────────────────────────

class FlutterFaceVerificationScreen extends StatefulWidget {
  final Uint8List? nfcImageBytes;
  final VoidCallback onBackPressed;

  final VoidCallback? onVerified;
  final DateTime? photoIssueDate;

  final FaceVerificationEngine? warmEngine;
  final Future<void>? warmEngineReady;

  /// Test-only selfie/probe image.
  ///
  /// When this is not null, the screen does not open the camera and does not
  /// initialize the real [FaceVerificationEngine]. It simulates the final
  /// comparison result by comparing [nfcImageBytes] with [testSelfieImageBytes].
  @visibleForTesting
  final Uint8List? testSelfieImageBytes;

  const FlutterFaceVerificationScreen({
    super.key,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
    this.warmEngine,
    this.warmEngineReady,
  }) : testSelfieImageBytes = null;

  const FlutterFaceVerificationScreen.withEngine({
    super.key,
    required FaceVerificationEngine engine,
    required this.nfcImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
  }) : warmEngine = engine,
       warmEngineReady = null,
       testSelfieImageBytes = null;

  const FlutterFaceVerificationScreen.withImageTest({
    super.key,
    required this.nfcImageBytes,
    required this.testSelfieImageBytes,
    required this.onBackPressed,
    this.onVerified,
    this.photoIssueDate,
  }) : warmEngine = null,
       warmEngineReady = null;

  @override
  State<FlutterFaceVerificationScreen> createState() => FlutterFaceVerificationScreenState();
}

// ── State ──────────────────────────────────────────────────────────────────

class FlutterFaceVerificationScreenState extends State<FlutterFaceVerificationScreen> with WidgetsBindingObserver {
  static const Map<DeviceOrientation, int> _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  FaceVerificationEngine? _engine;
  CameraController? _cameraController;
  CameraDescription? _activeCamera;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  // Whether the completed verification passed, computed once in [_onComplete]
  // against the age-based threshold and reused by the result screen.
  bool _passed = false;
  String? _errorMessage;
  VerificationState _state = VerificationState.idle;

  bool _cameraOpening = false;
  bool _cameraClosing = false;
  bool _isDisposed = false;
  bool _flowStopping = false;
  bool _startingLiveness = false;
  bool _engineReady = false;
  static const bool _debugReadyOverride = false;
  bool _previewMode = false;
  bool _previewAligned = false;
  bool _previewRestarting = false;
  bool _verificationRestarting = false;
  String? _alignTip;
  _PassiveProgress? _passive;
  DateTime? _passiveAt;

  Future<void>? _stopActiveFlowFuture;
  CameraImage? _pendingImage;
  bool _isSending = false;
  int _frameToken = 0;
  int _flowToken = 0;

  bool get _imageTestMode => widget.testSelfieImageBytes != null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!_imageTestMode) {
      _engine = widget.warmEngine ?? FaceVerificationEngine();
    }
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeEverything());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || _imageTestMode) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _previewMode = false;
      _previewAligned = false;
      unawaited(_stopActiveFlow(disposeCamera: true));
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _state == VerificationState.idle &&
        (_cameraController == null || _cameraController?.value.isInitialized != true)) {
      unawaited(_reopenCameraAndPreview());
    }
  }

  Future<void> _reopenCameraAndPreview() async {
    await _openCamera();
    if (_isDisposed || !mounted) return;
    await _startPreview();
  }

  // ── Bootstrap & cleanup ───────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    final nfcImage = widget.nfcImageBytes;
    if (nfcImage == null || nfcImage.isEmpty) {
      // No document photo to compare against — verification is impossible, so
      // fail immediately instead of opening the camera and erroring out later.
      if (mounted) setState(() => _state = VerificationState.failed);
      return;
    }

    if (_imageTestMode) {
      if (!mounted) return;
      setState(() => _engineReady = true);
      unawaited(_runImageTestVerification(nfcImage));
      return;
    }

    // Open camera first so the live feed is visible while models load.
    await _openCamera();
    if (!mounted) return;
    try {
      final engine = _engine;
      if (engine == null) {
        throw StateError("Face verification engine was not created");
      }

      if (widget.warmEngine != null) {
        // Models were already loaded in parallel with NFC reading (see
        // FdroidFaceVerifier.warmup). Just wait for that to finish — usually
        // already done by the time this screen opens.
        await (widget.warmEngineReady ?? Future<void>.value());
      } else {
        await engine.initialize(); // load models (cold path: no warmup)
      }
      if (!mounted) return;
      _eventSub = engine.events.listen(_onLivenessEvent);
      setState(() => _engineReady = true);

      // Start NFC decode + detection + embedding in background so it"s ready
      // before the user taps Start — eliminates the delay on first tap.
      unawaited(engine.prepareNfcFaceEagerly(nfcImage).catchError((_) {}));

      // Begin the alignment preview so the Start button can light up as soon as
      // the user's face is centered in the oval.
      unawaited(_startPreview());
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = FlutterI18n.translate(
            context,
            "face_verification.errors.could_not_start",
            translationParams: {"error": "$e"},
          ),
        );
      }
    }
  }

  Future<void> _runImageTestVerification(Uint8List nfcImage) async {
    final selfieImage = widget.testSelfieImageBytes;
    if (selfieImage == null || selfieImage.isEmpty) {
      if (mounted) setState(() => _state = VerificationState.failed);
      return;
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _state = VerificationState.processing;
      _errorMessage = null;
    });

    // Let the processing screen render once so the integration test exercises
    // the same visual transition as the real flow.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!mounted || _isDisposed) return;

    final sameImage = listEquals(nfcImage, selfieImage);

    _onComplete(VerificationResult(matchScore: sameImage ? 0.95 : 0.10, isLive: true));
  }

  Future<void> _disposeEverything() async {
    if (_imageTestMode) return;
    await _stopActiveFlow(disposeCamera: true);
    await _eventSub?.cancel();
    await _engine?.dispose();
  }

  Future<void> _stopActiveFlow({required bool disposeCamera}) {
    if (_imageTestMode) return Future<void>.value();

    _flowToken++;
    final runningStop = _stopActiveFlowFuture;
    if (runningStop != null) {
      if (!disposeCamera) return runningStop;
      return runningStop.then((_) async {
        final ctrl = _cameraController;
        if (ctrl != null) await _disposeCameraController(ctrl, disposeCamera: true);
      });
    }
    final stopFuture = _doStopActiveFlow(disposeCamera: disposeCamera);
    _stopActiveFlowFuture = stopFuture.whenComplete(() => _stopActiveFlowFuture = null);
    return _stopActiveFlowFuture!;
  }

  Future<void> _doStopActiveFlow({required bool disposeCamera}) async {
    if (_cameraClosing || _flowStopping) return;
    _flowStopping = true;
    try {
      _invalidateFramePipeline();
      await _engine?.stop();
      final ctrl = _cameraController;
      if (ctrl != null) await _disposeCameraController(ctrl, disposeCamera: disposeCamera);
    } finally {
      _flowStopping = false;
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    if (_isDisposed || _imageTestMode || _cameraOpening || _cameraClosing) return;
    if (_cameraController?.value.isInitialized == true) return;
    _cameraOpening = true;
    try {
      final cameras = await availableCameras();
      if (!mounted || _isDisposed) return;
      if (cameras.isEmpty) {
        setState(() => _errorMessage = FlutterI18n.translate(context, "face_verification.errors.no_camera"));
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      if (!mounted || _isDisposed) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _cameraController = ctrl;
        _activeCamera = front;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(
          () => _errorMessage = FlutterI18n.translate(
            context,
            "face_verification.errors.could_not_open_camera",
            translationParams: {"error": "$e"},
          ),
        );
      }
    } finally {
      _cameraOpening = false;
    }
  }

  Future<void> _disposeCameraController(CameraController ctrl, {required bool disposeCamera}) async {
    try {
      if (ctrl.value.isStreamingImages) await ctrl.stopImageStream();
    } catch (_) {}
    if (disposeCamera) {
      _cameraClosing = true;
      try {
        await ctrl.dispose();
      } catch (_) {}
      if (identical(_cameraController, ctrl)) _cameraController = null;
      _cameraClosing = false;
    }
  }

  int? _cameraFrameRotation() {
    final ctrl = _cameraController;
    final camera = _activeCamera ?? ctrl?.description;
    if (ctrl == null || camera == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      // iOS AVFoundation delivers BGRA buffers already portrait (system applies the
      // orientation transform internally). Android Camera2 does not — raw YUV comes out
      // in sensor orientation and needs the sensorOrientation correction.
      if (Platform.isIOS) return 0;
      return camera.sensorOrientation;
    }
    final rotationComp = _orientations[ctrl.value.deviceOrientation] ?? 0;
    return (camera.sensorOrientation - rotationComp + 360) % 360;
  }

  // ── Frame pipeline ────────────────────────────────────────────────────────

  void _invalidateFramePipeline() {
    _pendingImage = null;
    _isSending = false;
    _frameToken++;
  }

  // Frames feed the engine both during the alignment preview (idle) and during
  // a real liveness session.
  bool get _isFrameLoopActive => !_isDisposed && (_previewMode || _state == VerificationState.verifying);

  void _finalizeSendCycle(int token) {
    if (token != _frameToken) return;
    _isSending = false;
    if (_pendingImage != null && _isFrameLoopActive) {
      _isSending = true;
      unawaited(_sendLatestFrame(token));
    }
  }

  void _onCameraFrame(CameraImage image) {
    if (_isDisposed) return;
    if (!_previewMode && _state != VerificationState.verifying) return;
    if (_cameraClosing || _flowStopping) return;
    _pendingImage = image;
    if (!_isSending) {
      _isSending = true;
      final token = _frameToken;
      unawaited(_sendLatestFrame(token));
    }
  }

  Future<void> _sendLatestFrame(int token) async {
    try {
      while (_isFrameLoopActive && token == _frameToken) {
        final image = _pendingImage;
        if (image == null) break;
        _pendingImage = null;
        final rotation = _cameraFrameRotation();
        if (rotation == null) continue;
        await _engine?.processFrame(image, rotation);
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _previewMode = false;
        _previewAligned = false;
        _invalidateFramePipeline();
        setState(() {
          _state = VerificationState.idle;
          _errorMessage = FlutterI18n.translate(
            context,
            "face_verification.errors.processing_image",
            translationParams: {"error": "$e"},
          );
        });
      }
    } finally {
      _finalizeSendCycle(token);
    }
  }

  // ── Liveness ──────────────────────────────────────────────────────────────

  Future<void> _startLiveness() async {
    if (_startingLiveness || _state == VerificationState.verifying) return;
    if (!_engineReady) return;
    final ctrl = _cameraController;
    final nfcImage = widget.nfcImageBytes;
    if (_isDisposed || ctrl == null || !ctrl.value.isInitialized) return;
    if (nfcImage == null || nfcImage.isEmpty) {
      setState(() => _errorMessage = FlutterI18n.translate(context, "face_verification.errors.missing_photo"));
      return;
    }
    setState(() {
      _startingLiveness = true;
      _alignTip = null;
      _passive = null;
      _passiveAt = null;
    });
    final flowToken = _flowToken;
    try {
      await _doStartLiveness(ctrl, nfcImage);
    } catch (e) {
      if (flowToken == _flowToken && mounted && !_isDisposed) {
        setState(
          () => _errorMessage = FlutterI18n.translate(
            context,
            "face_verification.errors.could_not_start_verification",
            translationParams: {"error": "$e"},
          ),
        );
      }
    } finally {
      if (flowToken == _flowToken && mounted && !_isDisposed) {
        setState(() => _startingLiveness = false);
      }
    }
  }

  Future<void> _doStartLiveness(CameraController ctrl, Uint8List nfcImage) async {
    final flowToken = _flowToken;
    final engine = _engine;
    if (engine == null) return;

    await engine.start(nfcImage, mode: LivenessMode.passive);
    if (flowToken != _flowToken || !mounted || _isDisposed) return;
    setState(() {
      _state = VerificationState.verifying;
      _errorMessage = null;
    });
    if (flowToken != _flowToken || !mounted || _isDisposed) return;
    if (!ctrl.value.isStreamingImages) {
      await ctrl.startImageStream(_onCameraFrame);
    }
  }

  Future<void> _restartVerificationOnFaceLost() async {
    if (_isDisposed || _verificationRestarting) return;
    if (_state != VerificationState.verifying) return;
    final ctrl = _cameraController;
    final nfcImage = widget.nfcImageBytes;
    final engine = _engine;
    if (engine == null) return;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (nfcImage == null || nfcImage.isEmpty) return;

    _verificationRestarting = true;
    if (mounted) {
      setState(() {
        _passive = null;
        _passiveAt = null;
        _alignTip = "noFace";
      });
    }
    final flowToken = _flowToken;
    try {
      _invalidateFramePipeline();
      await engine.stop();
      if (_isDisposed || !mounted || flowToken != _flowToken) return;
      if (_state != VerificationState.verifying) return;
      await engine.start(nfcImage, mode: LivenessMode.passive);
      if (_isDisposed || !mounted || flowToken != _flowToken) return;
      if (!ctrl.value.isStreamingImages) {
        await ctrl.startImageStream(_onCameraFrame);
      }
    } catch (_) {
      // A transient restart failure just means the next aligned frames resume
      // lock-on; no need to surface an error for it.
    } finally {
      _verificationRestarting = false;
    }
  }

  void _onLivenessEvent(Map<String, dynamic> map) {
    if (_previewMode) {
      _handlePreviewEvent(map);
      return;
    }
    // While a face-lost restart is in flight, ignore stray events from the
    // session being torn down (e.g. a late progress or complete).
    if (_verificationRestarting) return;
    if (_handleCommonLivenessEvent(map)) return;
    if (map["type"] != "complete") return;
    final passed = map["passed"] as bool;
    final matchScore = (map["matchScore"] as num?)?.toDouble() ?? 0.0;
    _onComplete(VerificationResult(matchScore: matchScore, isLive: passed));
  }

  // ── Alignment preview ─────────────────────────────────────────────────────

  Future<void> _startPreview() async {
    if (_imageTestMode) return;
    if (_isDisposed || _previewMode || _startingLiveness) return;
    if (!_engineReady || _state != VerificationState.idle) return;
    final ctrl = _cameraController;
    final nfcImage = widget.nfcImageBytes;
    final engine = _engine;
    if (engine == null) return;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (nfcImage == null || nfcImage.isEmpty) return;
    _previewMode = true;
    if (mounted) {
      setState(() {
        _previewAligned = false;
        _alignTip = null;
      });
    }
    try {
      await engine.start(nfcImage, mode: LivenessMode.passive);
      if (_isDisposed || !mounted || !_previewMode) return;
      if (!ctrl.value.isStreamingImages) {
        await ctrl.startImageStream(_onCameraFrame);
      }
    } catch (_) {
      _previewMode = false;
    }
  }

  Future<void> _stopPreview() async {
    if (!_previewMode) return;
    _previewMode = false;
    if (mounted) setState(() => _previewAligned = false);
    _invalidateFramePipeline();
    await _engine?.stop();
  }

  Future<void> _restartPreview() async {
    if (_isDisposed || !_previewMode || _previewRestarting) return;
    _previewRestarting = true;
    try {
      _invalidateFramePipeline();
      await _engine?.stop();
      if (_isDisposed || !mounted || !_previewMode) return;
      final nfcImage = widget.nfcImageBytes;
      final engine = _engine;
      if (engine == null) return;
      if (nfcImage == null || nfcImage.isEmpty) return;
      await engine.start(nfcImage, mode: LivenessMode.passive);
      if (_isDisposed || !mounted || !_previewMode) return;
    } catch (_) {
      // Ignore: a transient restart failure just pauses gating briefly.
    } finally {
      _previewRestarting = false;
    }
  }

  void _handlePreviewEvent(Map<String, dynamic> map) {
    if (!mounted || _isDisposed) return;
    switch (map["type"] as String?) {
      case "align":
        final tip = map["tip"] as String?;
        final aligned = tip == "holdStill";
        if (tip != _alignTip || aligned != _previewAligned) {
          setState(() {
            _alignTip = tip;
            _previewAligned = aligned;
          });
        }
        // No Start button anymore: once the face is aligned in the oval the real
        // verification begins automatically. _startRealVerification guards against
        // re-entry, so repeated aligned frames are harmless.
        if (aligned) unawaited(_startRealVerification());
        break;
      case "passiveProgress":
        if (map["started"] == true) {
          if (!_previewAligned) setState(() => _previewAligned = true);
          unawaited(_startRealVerification());
        }
        break;
      case "processing":
      case "complete":
        unawaited(_restartPreview());
        break;
    }
  }

  // Tears down the preview and begins the real passive verification. Triggered
  // by the Start button, which is only enabled once the face is aligned.
  Future<void> _startRealVerification() async {
    if (_startingLiveness || !_previewMode) return;
    await _stopPreview();
    if (_isDisposed || !mounted) return;
    await _startLiveness();
  }

  bool _handleCommonLivenessEvent(Map<String, dynamic> map) {
    if (!mounted || _isDisposed) return false;
    if (_state != VerificationState.verifying && _state != VerificationState.processing) {
      return false;
    }
    final type = map["type"] as String?;
    if (type == null) return false;

    switch (type) {
      case "align":
        final tip = map["tip"] as String?;
        if (tip != _alignTip) setState(() => _alignTip = tip);
        if (tip == "noFace" && _passive?.started == true) {
          unawaited(_restartVerificationOnFaceLost());
        }
        return true;
      case "passiveProgress":
        return _handlePassiveProgressEvent(map);
      case "processing":
        setState(() => _state = VerificationState.processing);
        return true;
      case "timeout":
        return _handleTimeoutEvent(map);
      case "error":
        return _handleErrorEvent(map);
    }
    return false;
  }

  bool _handlePassiveProgressEvent(Map<String, dynamic> map) {
    final progress = _PassiveProgress(
      started: (map["started"] as bool?) ?? false,
      elapsedMs: (map["elapsedMs"] as num?)?.toInt() ?? 0,
      targetMs: (map["targetMs"] as num?)?.toInt() ?? 5000,
    );
    setState(() {
      _passive = progress;
      _passiveAt = DateTime.now();
    });
    return true;
  }

  bool _handleTimeoutEvent(Map<String, dynamic> map) {
    if (!mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(FlutterI18n.translate(context, "face_verification.timeout_hint")),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
    return true;
  }

  bool _handleErrorEvent(Map<String, dynamic> map) {
    final message = map["message"]?.toString() ?? "Unknown error";
    _invalidateFramePipeline();
    setState(() {
      _state = VerificationState.idle;
      _errorMessage = message;
    });

    return true;
  }

  void _onComplete(VerificationResult result) {
    if (!mounted || _isDisposed) return;
    _invalidateFramePipeline();
    final threshold = faceMatchThreshold(widget.photoIssueDate);
    final passed = result.matchScore > threshold && result.isLive;
    setState(() {
      _state = VerificationState.result;
      _passed = passed;
    });
    if (!_imageTestMode) {
      unawaited(_stopActiveFlow(disposeCamera: false));
    }
    // Briefly show the green check / red cross (like MRZ), then move on:
    // on success straight to the add screen, on failure to the retry screen.
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || _isDisposed) return;
      if (passed) {
        widget.onVerified?.call();
      } else {
        setState(() => _state = VerificationState.failed);
      }
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _retry() async {
    _previewMode = false;

    if (_imageTestMode) {
      final nfcImage = widget.nfcImageBytes;
      if (nfcImage == null || nfcImage.isEmpty) return;
      _resetForRetry();
      unawaited(_runImageTestVerification(nfcImage));
      return;
    }

    await _stopActiveFlow(disposeCamera: true);
    if (_isDisposed || !mounted) return;
    _resetForRetry();
    await _openCamera();
    if (_isDisposed || !mounted) return;
    await _startPreview();
  }

  void _resetForRetry() {
    setState(() {
      _passed = false;
      _errorMessage = null;
      _state = VerificationState.idle;
      _passive = null;
      _passiveAt = null;
      _alignTip = null;
      _previewAligned = false;
    });
  }

  void _handleBack() {
    _previewMode = false;
    if (!_imageTestMode) {
      unawaited(_stopActiveFlow(disposeCamera: true));
    }
    widget.onBackPressed();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleString: FlutterI18n.translate(context, "face_verification.title"),
        leading: YiviBackButton(onTap: _handleBack),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  bool get _isReady =>
      _debugReadyOverride || _imageTestMode || (_engineReady && _cameraController?.value.isInitialized == true);

  Widget _buildBody() {
    if (_errorMessage != null) return _buildErrorScreen();
    return switch (_state) {
      VerificationState.idle => _buildIdleScreen(),
      VerificationState.verifying => _buildVerifyingScreen(),
      VerificationState.processing => _buildProcessingScreen(),
      VerificationState.result => _buildResultScreen(),
      VerificationState.failed => _buildFailedScreen(),
    };
  }

  Widget? _buildPassiveProgressCard() {
    final p = _passive;
    if (p == null || !p.started) return null;
    return _PassiveCountdownCard(passive: p, passiveAt: _passiveAt);
  }

  Widget _buildCameraPreview() {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              Text(
                FlutterI18n.translate(context, "face_verification.preview.camera_opening"),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    final preview = ctrl.value.previewSize;
    if (preview == null) {
      return ColoredBox(color: Colors.black, child: CameraPreview(ctrl));
    }
    return ColoredBox(
      color: Colors.black,
      child: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: preview.height, height: preview.width, child: CameraPreview(ctrl)),
          ),
        ),
      ),
    );
  }

  // Blurs and darkens everything outside the oval, then draws the oval ring on
  // top. The ring turns green once the face is aligned, giving clear feedback.
  Widget _buildOvalOverlay({bool aligned = false}) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final ovalRect = faceOvalRect(size);
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _OvalCutoutClipper(ovalRect),
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
                ),
                CustomPaint(painter: _FaceOvalPainter(ovalRect, aligned: aligned)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdleScreen() {
    final aligned = _previewAligned;
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraPreview(),
        _buildOvalOverlay(aligned: aligned),
        // Status pill: tells the user how to line up. Verification starts on its
        // own once aligned — there is no Start button anymore.
        Positioned(top: 16, left: 16, right: 16, child: _buildPreviewStatus(aligned)),
      ],
    );
  }

  Widget _buildPreviewStatus(bool aligned) {
    final message = _previewStatusMessage(aligned);
    final color = aligned ? Colors.green.withValues(alpha: 0.85) : Colors.black54;
    final icon = aligned ? Icons.check_circle : Icons.face_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _previewStatusMessage(bool aligned) {
    if (!_isReady) return FlutterI18n.translate(context, "face_verification.preview.preparing");
    if (aligned) return FlutterI18n.translate(context, "face_verification.preview.aligned");
    final tip = _alignTip;
    return (tip != null ? _alignTipMessage(tip) : null) ??
        FlutterI18n.translate(context, "face_verification.preview.place_face");
  }

  Widget? _buildTipCard() {
    final tip = _alignTip;
    if (tip == null) return null;
    final message = _alignTipMessage(tip);
    if (message == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String? _alignTipMessage(String tip) {
    final key = switch (tip) {
      "noFace" => "no_face",
      "centerFace" => "center_face",
      "tooFar" => "too_far",
      "tooClose" => "too_close",
      "lookStraight" => "look_straight",
      "openEyes" => "open_eyes",
      "closeMouth" => "close_mouth",
      "relaxFace" => "relax_face",
      // Intentionally no message for "holdStill": while holding still the countdown
      // card is the only feedback, so a separate tip would just duplicate it.
      _ => null,
    };
    if (key == null) return null;
    return FlutterI18n.translate(context, "face_verification.tips.$key");
  }

  Widget _buildVerifyingScreen() {
    return Stack(fit: StackFit.expand, children: [_buildCameraPreview(), _buildOvalOverlay(), _buildTopInfoPanel()]);
  }

  Widget _buildTopInfoPanel() {
    final tipCard = _buildTipCard();
    final passiveCard = _buildPassiveProgressCard();

    final cards = <Widget>[];
    if (passiveCard != null) cards.add(passiveCard);
    if (tipCard != null) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: 8));
      cards.add(tipCard);
    }

    if (cards.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: cards),
    );
  }

  // After the countdown the camera is no longer needed: showing a plain loading
  // screen makes clear the user no longer has to hold still while we verify.
  Widget _buildProcessingScreen() => Center(
    key: const Key("face_verification_processing_screen"),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(FlutterI18n.translate(context, "face_verification.verifying"), style: const TextStyle(fontSize: 16)),
      ],
    ),
  );

  Widget _buildErrorScreen() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleBack,
            child: Text(FlutterI18n.translate(context, "face_verification.buttons.back")),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _retry,
            child: Text(FlutterI18n.translate(context, "face_verification.buttons.retry")),
          ),
        ],
      ),
    ),
  );

  Widget _buildResultScreen() {
    final passed = _passed;
    final color = passed ? Colors.green : Colors.red;
    // No camera here either — just the green check / red cross on a clean screen.
    return Center(
      key: const Key("face_verification_result_screen"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            key: Key(passed ? "face_verification_result_passed" : "face_verification_result_rejected"),
            width: 140,
            height: 140,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(passed ? Icons.check : Icons.close, color: Colors.white, size: 96),
          ),
          const SizedBox(height: 24),
          Text(
            FlutterI18n.translate(
              context,
              passed ? "face_verification.result.verified" : "face_verification.result.not_verified",
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedScreen() => Center(
    key: const Key("face_verification_failed_screen"),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            FlutterI18n.translate(context, "face_verification.failed.title"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(FlutterI18n.translate(context, "face_verification.failed.body"), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: YiviThemedButton(
              label: FlutterI18n.translate(context, "face_verification.buttons.retry"),
              onPressed: _retry,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _handleBack,
            child: Text(FlutterI18n.translate(context, "face_verification.buttons.back")),
          ),
        ],
      ),
    ),
  );
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _PassiveCountdownCard extends StatefulWidget {
  const _PassiveCountdownCard({required this.passive, required this.passiveAt});

  final _PassiveProgress passive;
  final DateTime? passiveAt;

  @override
  State<_PassiveCountdownCard> createState() => _PassiveCountdownCardState();
}

class _PassiveCountdownCardState extends State<_PassiveCountdownCard> {
  Timer? _ticker;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final s = _currentSecondsLeft();
      if (s != _lastSecond && mounted) setState(() => _lastSecond = s);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _currentSecondsLeft() => _computeSecondsLeft(DateTime.now());

  int _computeSecondsLeft(DateTime now) {
    final p = widget.passive;
    var elapsedMs = p.elapsedMs;
    if (widget.passiveAt != null) {
      elapsedMs += now.difference(widget.passiveAt!).inMilliseconds;
    }
    elapsedMs = elapsedMs.clamp(0, p.targetMs);
    return ((p.targetMs - elapsedMs) / 1000).ceil().clamp(0, 99);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final p = widget.passive;
    final secondsLeft = _computeSecondsLeft(now);
    var elapsedMs = p.elapsedMs;
    if (widget.passiveAt != null) {
      elapsedMs += now.difference(widget.passiveAt!).inMilliseconds;
    }
    elapsedMs = elapsedMs.clamp(0, p.targetMs);
    final remainingMs = (p.targetMs - elapsedMs).clamp(0, p.targetMs);
    final progress = p.targetMs == 0 ? 0.0 : (remainingMs / p.targetMs).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FlutterI18n.translate(context, "face_verification.countdown.hold_still"),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                secondsLeft <= 0
                    ? FlutterI18n.translate(context, "face_verification.countdown.almost_done")
                    : FlutterI18n.translate(
                        context,
                        "face_verification.countdown.seconds_left",
                        translationParams: {"seconds": "$secondsLeft"},
                      ),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
            ),
          ),
        ],
      ),
    );
  }
}

Rect faceOvalRect(Size size) {
  final ovalWidth = math.min(size.width * 0.80, size.height * 0.90 * (3 / 4));
  final ovalHeight = ovalWidth * (4 / 3);
  return Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.46), width: ovalWidth, height: ovalHeight);
}

class _OvalCutoutClipper extends CustomClipper<Path> {
  const _OvalCutoutClipper(this.ovalRect);

  final Rect ovalRect;

  @override
  Path getClip(Size size) {
    return Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addOval(ovalRect));
  }

  @override
  bool shouldReclip(_OvalCutoutClipper old) => old.ovalRect != ovalRect;
}

class _FaceOvalPainter extends CustomPainter {
  const _FaceOvalPainter(this.ovalRect, {required this.aligned});

  final Rect ovalRect;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = aligned ? Colors.greenAccent : Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4.0 : 2.5,
    );
  }

  @override
  bool shouldRepaint(_FaceOvalPainter old) => old.ovalRect != ovalRect || old.aligned != aligned;
}
