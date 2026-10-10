import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";

/// A [FileTranslationLoader] that reads the locale files from disk instead of
/// through `rootBundle`.
///
/// `rootBundle` decodes an asset of 50 KiB or more on an isolate, and an
/// isolate never answers under the fake clock of `testWidgets`, so a test
/// that loads such a file through the plain loader waits for it forever.
/// `en.json` is past that size. Reading the file synchronously needs no
/// isolate.
class SyncFileTranslationLoader extends FileTranslationLoader {
  SyncFileTranslationLoader({
    super.fallbackFile,
    super.basePath,
    super.forcedLocale,
  });

  @override
  Future<String> loadString(String fileName, String extension) {
    final path = "$basePath/$fileName.$extension".replaceFirst(
      "packages/yivi_core/",
      "",
    );
    return SynchronousFuture(File(path).readAsStringSync());
  }
}
