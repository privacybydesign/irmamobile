import 'package:flutter/services.dart';

class PrivacyScreen {
  static final MethodChannel _channel = MethodChannel('privacy_screen');

  static Future<void> enablePrivacyScreen() async {
    await _channel.invokeMethod('enablePrivacyScreen');
  }

  static Future<void> disablePrivacyScreen() async {
    await _channel.invokeMethod('disablePrivacyScreen');
  }
}
