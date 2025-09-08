import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_parser/mrz_parser.dart';

// import 'camera_viewfinder.dart';
// import 'mrz_helper.dart';

class MRZScanner extends StatefulWidget {
  const MRZScanner({
    Key? controller,
    required this.onSuccess,
    this.initialDirection = CameraLensDirection.back,
    this.showOverlay = true,
  }) : super(key: controller);
  final Function(MRZResult mrzResult, List<String> lines) onSuccess;
  final CameraLensDirection initialDirection;
  final bool showOverlay;
  @override
  // ignore: library_private_types_in_public_api
  MRZScannerState createState() => MRZScannerState();
}

class MRZScannerState extends State<MRZScanner> {
  CameraController? _controller;
  int _cameraIndex = 1;
  List<CameraDescription> cameras = [];

  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _canProcess = true;
  bool _isBusy = false;
  List result = [];

  void resetScanning() => _isBusy = false;
  void dataScanned() => _isBusy = true; //to avoid continuous scanning even after data is received

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller?.value.isInitialized == false || _controller?.value.isInitialized == null) {
      return Container();
    }
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  initCamera() async {
    cameras = await availableCameras();

    try {
      if (cameras
          .any((element) => element.lensDirection == widget.initialDirection && element.sensorOrientation == 90)) {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection && element.sensorOrientation == 90,
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
      if (kDebugMode) {
        print(e);
      }
    }

    _startLiveFeed();
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }

      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  void _parseScannedText(List<String> lines) {
    try {
      final data = MRZParser.parse(lines);
      _isBusy = true;

      widget.onSuccess(data, lines);
    } catch (e) {
      _isBusy = false;
    }
  }

  Future _processCameraImage(CameraImage image) async {
    return;
    // final inputImage = _inputImageFromCameraImage(image);
    // if (inputImage == null) return;
    // widget.onImage(inputImage);
  }

  Future<void> _processImage(InputImage inputImage) async {
    return;
    // if (!_canProcess) return;
    // if (_isBusy) return;
    // _isBusy = true;

    // try {
    //   final recognizedText = await _textRecognizer.processImage(inputImage);
    //   String fullText = recognizedText.text;
    //   String trimmedText = fullText.replaceAll(' ', '');
    //   List allText = trimmedText.split('\n');

    //   List<String> ableToScanText = [];
    //   for (var e in allText) {
    //     if (MRZHelper.testTextLine(e).isNotEmpty) {
    //       ableToScanText.add(MRZHelper.testTextLine(e));
    //     }
    //   }
    //   List<String>? result = MRZHelper.getFinalListToParse([...ableToScanText]);

    //   if (result != null) {
    //     _parseScannedText([...result]);
    //   } else {
    //     _isBusy = false;
    //   }
    // } catch (e) {
    //   print('Error processing image: $e');
    //   _isBusy = false;
    // }
  }
}
