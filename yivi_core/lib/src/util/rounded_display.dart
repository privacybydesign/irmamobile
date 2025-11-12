import 'dart:io';

import 'package:flutter/material.dart';

/// Returns whether or not the device has a rounded display.
/// Useful to make layout exceptions for newer iPhones for example.
bool hasRoundedDisplay(BuildContext context) {
  if (!Platform.isIOS) {
    return false; // Not an iOS device
  }

  // Get screen dimensions
  final size = MediaQuery.of(context).size;
  final aspectRatio = size.height / size.width;

  // Get safe area insets
  final padding = MediaQuery.of(context).padding;

  // Check if the device has rounded corners or a notch
  final isRounded = padding.top > 20.0 || padding.bottom > 0.0;

  // List of known aspect ratios for rounded iOS devices (adjust as necessary)
  final roundedAspectRatios = [2.16, 2.17, 2.34];

  return isRounded && roundedAspectRatios.any((ratio) => (aspectRatio - ratio).abs() < 0.01);
}
