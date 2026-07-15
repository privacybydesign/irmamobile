# irmamobile — notes for future work

## Layout

Three Flutter packages, no monorepo tool:

- `yivi_core` — all shared UI, data and business logic; the app itself lives
  here (`runYiviApp` in `yivi_core/lib/yivi_core.dart`).
- `yivi_app` — Play Store / App Store build. Injects proprietary
  implementations (ML Kit OCR, mobile_scanner, in_app_review) into
  `runYiviApp`.
- `yivi_fdroid` — FOSS build. Injects FOSS-only implementations and passes
  `null` for anything proprietary, which gates the feature off.

## Injecting a proprietary dependency

Keep non-FOSS packages out of `yivi_core`. The pattern (see `ocrProcessor`,
`smsRetriever`, `storeReviewService`):

1. Define an abstract interface + a `Provider<T?>((ref) => null)` in
   `yivi_core`.
2. Add a nullable parameter to `runYiviApp` and override the provider with it.
3. `yivi_app` passes a concrete impl; `yivi_fdroid` omits it (stays null).
4. Consumers null-check the provider so the FOSS build no-ops.

## Tooling

- Flutter is pre-installed at `/opt/flutter` (matches CI). `export
  PATH="/opt/flutter/bin:$PATH"`, then `flutter pub get` / `flutter analyze` /
  `flutter test` all run locally.
- CI lint runs `dart format --set-exit-if-changed lib test` — run it before
  pushing.

## Test gotchas

- `assets/locales/{en,nl,de}.json` must have identical key sets;
  `test/locale_completeness_test.dart` fails otherwise. `en` is the reference.
- `StreamingSharedPreferences.instance` (behind `IrmaPreferences`) is a
  process-wide singleton whose in-memory values survive across tests in a file.
  `SharedPreferences.setMockInitialValues({})` does not reset them — call
  `IrmaPreferences.clearAll()` per test, or assert on a delta from a baseline.
