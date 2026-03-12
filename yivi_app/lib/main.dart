import "dart:io";

import "package:smart_auth/smart_auth.dart";
import "package:yivi_core/yivi_core.dart";

import "ocr_processor.dart";
import "sms_retriever.dart";

void main() {
  runYiviApp(
    ocrProcessor: GoogleMLKitOcrProcessor(),
    smsRetriever: Platform.isAndroid
        ? SmartAuthSmsRetriever(SmartAuth.instance)
        : null,
  );
}
