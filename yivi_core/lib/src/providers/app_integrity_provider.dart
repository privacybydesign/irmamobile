import "package:flutter_riverpod/flutter_riverpod.dart";

import "../screens/app_integrity/app_integrity.dart";

final appIntegrityProvider = Provider<AppIntegrity>(
  (ref) => RealAppIntegrity(),
);
