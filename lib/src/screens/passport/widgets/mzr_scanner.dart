import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_parser/mrz_parser.dart';

import 'camera_viewfinder.dart';
import 'mrz_helper.dart';

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
  Widget build(BuildContext context) {
    return MRZCameraView(
      showOverlay: widget.showOverlay,
      initialDirection: widget.initialDirection,
      onImage: _processImage,
    );
  }

  bool _parseScannedText(List<String> lines) {
    try {
      final data = MRZParser.parse(lines);
      _isBusy = true;

      widget.onSuccess(data, lines);
      return true;
    } catch (e) {
      _isBusy = false;
    }
    return false;
  }

  Future<bool> _processImage(InputImage inputImage) async {
    if (!_canProcess) return false;
    if (_isBusy) return false;
    _isBusy = true;

    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      String trimmedText = fullText.replaceAll(' ', '');
      List allText = trimmedText.split('\n');

      List<String> ableToScanText = [];
      for (var e in allText) {
        if (MRZHelper.testTextLine(e).isNotEmpty) {
          ableToScanText.add(MRZHelper.testTextLine(e));
        }
      }
      List<String>? result = MRZHelper.getFinalListToParse([...ableToScanText]);

      if (result != null) {
        return _parseScannedText([...result]);
      } else {
        _isBusy = false;
      }
    } catch (e) {
      _isBusy = false;
    }
    return false;
  }
}
