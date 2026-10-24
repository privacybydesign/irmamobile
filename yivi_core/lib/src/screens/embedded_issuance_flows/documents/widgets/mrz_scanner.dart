import "package:camera/camera.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";

import "../../../../providers/ocr_processor_provider.dart";
import "../../../../util/mrz_glare.dart";
import "../../../../util/mrz_reading.dart";
import "../../../../util/test_detection.dart";
import "document_camera_frame.dart";
import "mrz_camera_feed.dart";

class MrzScanner<Parser extends MrzParser> extends ConsumerStatefulWidget {
  const MrzScanner({
    Key? controller,
    required this.onSuccess,
    required this.mrzParser,
  }) : super(key: controller);
  final void Function(MrzResult mrzResult) onSuccess;
  final Parser mrzParser;

  @override
  // ignore: library_private_types_in_public_api
  MrzScannerState createState() => MrzScannerState();
}

/// Reads the MRZ from the camera. The camera runs only while the scanner is
/// on screen: its route is the current one, its tickers are on (a page in a
/// sheet under another is not), and the app is in the foreground. Otherwise,
/// and when the scanner goes away, the camera is released.
class MrzScannerState extends ConsumerState<MrzScanner>
    with WidgetsBindingObserver {
  bool _canProcess = true;
  bool _isBusy = false;
  bool _showSuccessCheck = false;
  final _confirmation = MrzReadingConfirmation();
  final _glareHint = GlareHint();
  bool _showGlareHint = false;

  late final MrzCameraFeed _feed = ref.read(mrzCameraFeedProvider)();
  bool _routeShown = true;
  bool _tickersOn = true;
  bool _appActive = true;

  /// The camera is wanted now.
  bool get _wanted =>
      mounted && _routeShown && _tickersOn && _appActive && _canProcess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Both change when a route is pushed over this one or popped off it,
    // and when the page goes under another one or offstage.
    _routeShown = ModalRoute.of(context)?.isCurrent ?? true;
    _tickersOn = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _canProcess = false;
    // Releases the camera: without this it stayed on after the flow.
    _feed.stop();
    super.dispose();
  }

  /// Starts or stops the camera to match [_wanted].
  Future<void> _sync() async {
    // Inside integration tests there is no camera to use.
    if (mounted && TestContext.isRunningIntegrationTest(context)) return;
    if (_wanted) {
      if (_feed.running) return;
      _confirmation.reset();
      _glareHint.reset();
      _showGlareHint = false;
      await _feed.start(_processImage);
      if (!_wanted) {
        // Covered (or gone) while starting.
        await _feed.stop();
        return;
      }
      if (mounted) setState(() {});
    } else {
      await _feed.stop();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // One frame for every document, with the glare hint in its hint card.
    return DocumentCameraFrame(
      found: _showSuccessCheck,
      glare: _showGlareHint,
      child: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    final preview = _feed.preview();
    if (preview == null) return Container();

    final mediaQuery = MediaQuery.of(context);
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = mediaQuery.size.aspectRatio * _feed.aspectRatio;

    if (mediaQuery.orientation == .landscape) {
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
                aspectRatio: mediaQuery.orientation == .portrait
                    ? 9 / 16
                    : 16 / 9,
                child: preview,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _processImage(CameraImage inputImage) async {
    // A frame can still come in after the camera was asked to stop.
    if (!_wanted) return false;
    if (_isBusy) return false;
    _isBusy = true;

    try {
      final rotation = _feed.imageRotation();
      if (rotation == null) {
        return false;
      }

      final ocr = await ref
          .read(ocrProcessorProvider)!
          .processImage(inputImage: inputImage, imageRotation: rotation);
      final lines = ocr.lines;

      final showGlareHint = _glareHint.update(ocr.reflection);
      if (showGlareHint != _showGlareHint && mounted) {
        setState(() => _showGlareHint = showGlareHint);
      }

      final parsed = widget.mrzParser.tryParse(
        lines == null ? null : correctDocumentNumber(lines),
      );
      final result = parsed == null ? null : _confirmation.confirm(parsed);

      if (result != null && mounted) {
        // show success checkmark for a second and then call the onSuccess callback
        setState(() {
          _showSuccessCheck = true;
        });
        await Future.delayed(Duration(seconds: 1));
        if (!mounted) return false;
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
