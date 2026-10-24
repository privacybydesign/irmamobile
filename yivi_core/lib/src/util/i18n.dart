import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

/// Translations at a [BuildContext].
extension YiviI18n on BuildContext {
  /// [key] translated into the app's language, with [params] filled in.
  String tr(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(this, key, translationParams: params);

  /// The code of the app's language, e.g. "nl".
  String get lang => FlutterI18n.currentLocale(this)?.languageCode ?? "en";
}
