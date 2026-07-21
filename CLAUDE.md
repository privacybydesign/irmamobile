# irmamobile / Yivi app — repo notes

## Layout
- `yivi_core/` — shared Flutter package (widgets, providers, models). Pure-Dart
  and Flutter code used by both apps; add cross-flavor dependencies here.
- `yivi_app/` — the Play Store / App Store build (root package).
- `yivi_fdroid/` — the FOSS F-Droid build (root package, no proprietary deps).

## Dependency gotcha: pointycastle source conflict
`vcmrtd` (and the mrz stack) pull `pointycastle` from the
`privacybydesign/pc-dart` git fork, while several pub.dev packages (e.g.
`altcha_lib`) declare `pointycastle` from hosted. Pub cannot unify a git and a
hosted source for one package, so version solving fails.

Fix: a `dependency_overrides` pinning `pointycastle` to the fork. The fork
reports version `4.0.0`, so it satisfies `^4.0.0` constraints. Because
`dependency_overrides` only take effect in the **root** package, the override
must be repeated in **all three** pubspecs — `yivi_core`, `yivi_app`, and
`yivi_fdroid` — whenever a new hosted dep transitively wants `pointycastle`.
