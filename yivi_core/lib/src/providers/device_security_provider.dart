import "package:flutter_riverpod/flutter_riverpod.dart";

import "../screens/device_lock/device_security.dart";

final deviceSecurityProvider = Provider<DeviceSecurity>(
  (ref) => RealDeviceSecurity(),
);
