# Repo notes for automated contributors

Concise, durable gotchas for working in this repo. Keep it factual and short.

## Layout

Multi-package Flutter workspace:

- `yivi_core/` — shared library: models, screens, widgets, the `irmagobridge`
  Go bridge to [irmago](https://github.com/privacybydesign/irmago), and the
  `assets/locales/` translations. Most feature code and its unit tests live here.
- `yivi_app/` — the host app (Android/iOS entry points, integration tests).
- `yivi_fdroid/` — F-Droid build variant.

## Tests

- Dart unit/widget tests: `cd yivi_core && flutter test`.
- The CI `unit-test` job runs `bundle exec fastlane unit_test`, which runs
  `flutter test` **and** the Android-native JVM tests via
  `./gradlew :yivi_core:testDebugUnitTest`. The Gradle step first builds the
  irmagobridge AAR and runs `flutter build apk --config-only --flavor alpha` to
  materialise `./gradlew` (the wrapper is gitignored). Because of this, a
  transient Maven Central `403 Forbidden` on Kotlin artifacts can fail the whole
  `unit-test` check even when every Dart test passes — that is flaky infra,
  re-run the job.

## Translations

Three locales live in `yivi_core/assets/locales/`: `de.json`, `en.json`,
`nl.json`. `test/locale_completeness_test.dart` fails unless all three define
exactly the same keys, so add every new key to all three. `nl` addresses the
user informally (`je`); `de` uses the formal `Sie`.

## Codegen

Model (de)serialization uses `json_serializable`. After editing a `*.dart`
model with generated `*.g.dart`, regenerate with `./codegen.sh` (runs
`dart run build_runner build --delete-conflicting-outputs` in `yivi_core`).
