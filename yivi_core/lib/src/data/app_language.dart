import "package:flutter/widgets.dart";
import "package:rxdart/rxdart.dart";

import "../util/language.dart";
import "irma_preferences.dart";

/// The effective app language — the in-app language override when set,
/// otherwise the device language — and every change to it.
///
/// Owns the only framework wiring the language needs: a
/// [WidgetsBindingObserver] on the device locale, so switching language in the
/// system settings is picked up while the app is running rather than at the
/// next start.
class AppLanguage with WidgetsBindingObserver {
  AppLanguage(this._preferences) {
    WidgetsBinding.instance.addObserver(this);
  }

  final IrmaPreferences _preferences;

  final _systemLocale = BehaviorSubject<Locale>.seeded(
    WidgetsBinding.instance.platformDispatcher.locale,
  );

  /// The language right now, as a bare language code ("nl"), without waiting
  /// for [changes] to emit.
  String get current => effectiveAppLanguage(
    preferredLanguageCode: _preferences.preferredLanguageCode,
    systemLocale: _systemLocale.value,
  );

  /// Every change to [current], starting from the value it held when this
  /// stream was first listened to. Seeding with that value lets `distinct`
  /// drop the combined stream's first emission when it merely repeats it, and
  /// `skip(1)` drops the seed itself — so a listener sees changes only,
  /// whichever source emits first.
  late final Stream<String> changes = Rx.combineLatest2(
    _preferences.getPreferredLanguageCode(),
    _systemLocale.stream,
    (String preferred, Locale systemLocale) => effectiveAppLanguage(
      preferredLanguageCode: preferred,
      systemLocale: systemLocale,
    ),
  ).startWith(current).distinct().skip(1);

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales == null || locales.isEmpty) return;
    _systemLocale.add(locales.first);
  }

  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await _systemLocale.close();
  }
}
