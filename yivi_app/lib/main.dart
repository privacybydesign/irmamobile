import "package:yivi_core/yivi_core.dart";

import "mrz_processor.dart";

void main() {
  runYiviApp(mrzProcessor: GoogleMLKitMrzProcessor());
}
