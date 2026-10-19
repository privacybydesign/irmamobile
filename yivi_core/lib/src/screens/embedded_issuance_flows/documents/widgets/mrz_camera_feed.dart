import "dart:io";

import "package:camera/camera.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

/// The camera behind the MRZ scanner: started while the scanner is on screen
/// and stopped (the camera released, so the system's camera indicator goes
/// off) as soon as it is not. A fake in tests ([mrzCameraFeedProvider]).
abstract class MrzCameraFeed {
  /// Whether the camera is streaming frames to [start]'s `onImage`.
  bool get running;

  /// The preview, once [running]; null before.
  Widget? preview();

  /// The preview's width by height, as the camera reports it (landscape).
  double get aspectRatio;

  /// How the frames of the current camera must be turned to read upright,
  /// or null when that is not known (yet).
  int? imageRotation();

  /// Opens the camera and streams its frames to [onImage]. Does nothing
  /// while already running.
  Future<void> start(void Function(CameraImage image) onImage);

  /// Stops the stream and releases the camera. Safe to call at any time,
  /// also while a [start] is still under way: that one then releases it.
  Future<void> stop();
}

/// Makes the camera feed for a scanner; the real camera in the app.
final mrzCameraFeedProvider = Provider<MrzCameraFeed Function()>(
  (ref) => _CameraControllerFeed.new,
);

/// [MrzCameraFeed] on the `camera` plugin: the back camera with a sensor at
/// 90 degrees when there is one.
class _CameraControllerFeed implements MrzCameraFeed {
  CameraController? _controller;
  CameraDescription? _camera;

  /// Bumped by [stop]: a [start] that was under way sees it and releases
  /// what it opened itself.
  int _generation = 0;
  bool _starting = false;

  @override
  bool get running => _controller?.value.isStreamingImages ?? false;

  @override
  Widget? preview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return CameraPreview(controller);
  }

  @override
  double get aspectRatio => _controller?.value.aspectRatio ?? 16 / 9;

  static const Map<DeviceOrientation, int> _orientations = {
    .portraitUp: 0,
    .landscapeLeft: 90,
    .portraitDown: 180,
    .landscapeRight: 270,
  };

  @override
  int? imageRotation() {
    final camera = _camera;
    if (camera == null) return null;
    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isIOS) return sensorOrientation;
    if (!Platform.isAndroid) return null;
    // A frame can still arrive after stop has dropped the controller.
    final controller = _controller;
    if (controller == null) return null;
    final compensation = _orientations[controller.value.deviceOrientation];
    if (compensation == null) return null;
    return camera.lensDirection == .front
        ? (sensorOrientation + compensation) % 360
        : (sensorOrientation - compensation + 360) % 360;
  }

  static Future<CameraDescription?> _pick() async {
    final cameras = await availableCameras();
    final back = cameras.where((c) => c.lensDirection == .back);
    return back.where((c) => c.sensorOrientation == 90).firstOrNull ??
        back.firstOrNull ??
        cameras.firstOrNull;
  }

  @override
  Future<void> start(void Function(CameraImage image) onImage) async {
    if (_controller != null || _starting) return;
    _starting = true;
    final generation = ++_generation;
    CameraController? controller;
    try {
      final camera = _camera ??= await _pick();
      if (camera == null || generation != _generation) return;
      controller = CameraController(
        camera,
        .veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? .nv21 : .bgra8888,
      );
      await controller.initialize();
      if (generation != _generation) return await _release(controller);
      await controller.startImageStream(onImage);
      if (generation != _generation) return await _release(controller);
      _controller = controller;
    } catch (e) {
      debugPrint("could not start the camera: $e");
      if (controller != null) await _release(controller);
    } finally {
      _starting = false;
    }
  }

  @override
  Future<void> stop() async {
    // A start under way sees this and releases the camera itself.
    _generation++;
    final controller = _controller;
    if (controller == null) return;
    await _release(controller);
  }

  Future<void> _release(CameraController controller) async {
    if (_controller == controller) _controller = null;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint("failed to stop image stream: $e");
    }
    await controller.dispose();
  }
}
