import "package:flutter_riverpod/flutter_riverpod.dart";

import "../screens/rooted_warning/rooted_device_detector.dart";

final rootedDeviceDetectorProvider = Provider<RootedDeviceDetector>(
  (ref) => RealRootedDeviceDetector(),
);
