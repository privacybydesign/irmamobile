import "dart:io";

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mrz_parser/mrz_parser.dart";

import "../../../../routing.dart";
import "../../../providers/ocr_processor_provider.dart";
import "../../../util/test_detection.dart";

typedef CameraOverlayBuilder =
    Widget Function({required bool success, required Widget child});

class MrzScanner<Parser extends MrzParser> extends ConsumerStatefulWidget {
  const MrzScanner({
    Key? controller,
    required this.onSuccess,
    this.initialDirection = .back,
    required this.overlayBuilder,
    required this.mrzParser,
  }) : super(key: controller);
  final void Function(MrzResult mrzResult) onSuccess;
  final CameraLensDirection initialDirection;
  final CameraOverlayBuilder overlayBuilder;
  final Parser mrzParser;

  @override
  // ignore: library_private_types_in_public_api
  MrzScannerState createState() => MrzScannerState();
}

class MrzScannerState extends ConsumerState<MrzScanner>
    with RouteAware, WidgetsBindingObserver {
  bool _canProcess = true;
  bool _isBusy = false;
  List result = [];
  bool _showSuccessCheck = false;
  CameraController? _controller;
  int _cameraIndex = 1;
  List<CameraDescription> cameras = [];

  @override
  void dispose() async {
    routeObserver.unsubscribe(this);
    _canProcess = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initCamera());
  }

  initCamera() async {
    // inside of integration tests we don't want to use the actual camera
    if (TestContext.isRunningIntegrationTest(context)) {
      return;
    }

    cameras = await availableCameras();

    try {
      if (cameras.any(
        (element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90,
      )) {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) =>
                element.lensDirection == widget.initialDirection &&
                element.sensorOrientation == 90,
          ),
        );
      } else {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection,
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _startLiveFeed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() async {
    // Called when the current route has been pushed.
    await _startLiveFeed();
  }

  @override
  void didPushNext() async {
    // Called when a new route has been pushed, and this route is no longer visible.
    await _stopLiveFeed();
  }

  // Called when the top route has been popped and this route shows again.
  @override
  void didPopNext() async {
    // For some reason an exception is sometimes triggered when going back from a session screen.
    // This doesn't have any effect for the user, but in order to prevent it from showing up in
    // Sentry logging we catch it here and pretend like nothing happened...
    try {
      await _startLiveFeed();
    } catch (e) {
      debugPrint("error while starting live feed: $e");
    }
  }

  // Called when this route is popped.
  @override
  void didPop() async {
    await _stopLiveFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.overlayBuilder(
        success: _showSuccessCheck,
        child: _liveFeedBody(),
      ),
    );
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false ||
        _controller?.value.isInitialized == null) {
      return Container();
    }

    final mediaQuery = MediaQuery.of(context);
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = mediaQuery.size.aspectRatio * _controller!.value.aspectRatio;

    if (mediaQuery.orientation == Orientation.landscape) {
      scale = 1;
    } else {
      // to prevent scaling down, invert the value
      if (scale < 1) scale = 1 / scale;
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale,
            child: Center(
              child: AspectRatio(
                aspectRatio: mediaQuery.orientation == Orientation.portrait
                    ? 9 / 16
                    : 16 / 9,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _startLiveFeed() async {
    if (cameras.isEmpty) return;

    if (_controller != null && _controller!.value.isInitialized) {
      if (!_controller!.value.isStreamingImages) {
        await _controller!.startImageStream(_processImage);
      }
      return;
    }

    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    if (!mounted) {
      return;
    }

    await _controller?.initialize();
    if (!mounted) {
      return;
    }

    await _controller?.startImageStream(_processImage);

    setState(() {});
  }

  Future _stopLiveFeed() async {
    if (_controller == null) {
      return;
    }
    final c = _controller;
    // first to a setState to make sure the build method doesn't use the controller while it's disposed
    setState(() {
      _controller = null;
    });

    // wait a little bit to make sure the controller is no longer used
    await Future.delayed(const Duration(milliseconds: 20));

    // stop stream & dispose
    try {
      if (c?.value.isStreamingImages == true) {
        await c?.stopImageStream();
      }
    } catch (e) {
      debugPrint("failed to stop image stream: $e");
    }
    await c?.dispose();
  }

  static const Map<DeviceOrientation, int> _orientations = {
    .portraitUp: 0,
    .landscapeLeft: 90,
    .portraitDown: 180,
    .landscapeRight: 270,
  };

  int? _getImageRotation() {
    final camera = cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isIOS) {
      return sensorOrientation;
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == .front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      return rotationCompensation;
    }
    return null;
  }

  Future _processImage(CameraImage inputImage) async {
    if (!_canProcess) return false;
    if (_isBusy) return false;
    _isBusy = true;

    try {
      final rotation = _getImageRotation();
      if (rotation == null) {
        return false;
      }

      final lines = await ref
          .read(ocrProcessorProvider)!
          .processImage(inputImage: inputImage, imageRotation: rotation);

      final result = widget.mrzParser.tryParse(lines);

      if (result != null) {
        // show success checkmark for a second and then call the onSuccess callback
        setState(() {
          _showSuccessCheck = true;
        });
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          _showSuccessCheck = false;
        });
        widget.onSuccess(result);
      }
    } finally {
      _isBusy = false;
    }
  }
}
