import "dart:convert";

import "package:flutter/services.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";

/// [FileTranslationLoader] for widget tests.
///
/// `rootBundle.loadString` decodes assets of 50 KB or more on a background
/// isolate, which never completes under the widget tester's fake async; the
/// locale files are past that size. This loader decodes on the test isolate.
class TestTranslationLoader extends FileTranslationLoader {
  TestTranslationLoader({super.basePath, super.forcedLocale}) {
    assetBundle = _SyncDecodingAssetBundle();
  }
}

class _SyncDecodingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode((await load(key)).buffer.asUint8List());
}
