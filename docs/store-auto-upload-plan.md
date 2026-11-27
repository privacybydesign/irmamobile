# Automatic store upload plan

**Status (2026-11-27):** steps 1–5 built on branch `auto-upload` (worktree
`../irmamobile-auto-upload`), not committed. Step 6 (credentials) and 7 (first runs)
still to do. Decisions taken: the dry run is manual only (open question 2), Play
releases go out as `completed` (open question 3).

Goal: a merge to `master` that raises the build number in `yivi_app/pubspec.yaml`
uploads the iOS build to **TestFlight** (internal testers) and the Android build to
the **Play internal track**, without anyone downloading artifacts and uploading them
by hand. Moving a build further (external TestFlight, App Store review, closed/open
testing, production) stays a manual step in the store consoles.

Model: the Idem app in `privacybydesign/vcmrtd` (commit `c5c2063` and follow-ups on
its `master`): `.github/workflows/delivery.yml`,
`.github/workflows/dry-run-distribution.yml`, `idem/fastlane/Fastfile`. That setup
was itself modelled on irmamobile, so most of the structure is already here.

Branch: `auto-upload` (currently empty and 220 commits behind `master`; reset it to
`master` first).

## What irmamobile already has

- `delivery.yml` → `version-check` job, and `build-app-ios-beta` /
  `build-app-android-beta` that run only when it passes.
- Environments `app-store-beta` (distribution certificate + app store profile for
  `foundation.privacybydesign.irmamob`) and `android-beta` (Play upload keystore,
  alias `android-play-store-upload-key`).
- Both jobs upload the IPA/AAB as an artifact, then the Dart symbols to Sentry.
- `ITSAppUsesNonExemptEncryption = false` in `Info.plist`, so TestFlight builds do
  not wait on an export-compliance question.
- Both apps already exist in the stores, so (unlike Idem) no first manual upload is
  needed.

## What is missing

1. Fastlane lanes that upload.
2. Upload steps in the two beta jobs.
3. Store credentials in the two environments.
4. A version check that only fires on a real build-number increase.
5. (Optional) a dry run that validates the upload path without publishing.

## Steps

### 1. Fastlane lanes (`fastlane/Fastfile`, `fastlane/Appfile`)

Copy from Idem, adjusted for paths and identifiers:

- `ios_upload_testflight(key_id, issuer_id, key_filepath, ipa_path?)`
  - `app_store_connect_api_key(...)` → `upload_to_testflight(api_key:, ipa:,
    skip_waiting_for_build_processing: true, skip_submission: true,
    distribute_external: false)`.
  - Default IPA: `build/*.ipa` (the beta job only produces
    `app-beta-ios-app-store.ipa`).
- `android_upload_play_store(json_key_path, aab_path?, validate_only?)`
  - `upload_to_play_store(package_name: "org.irmacard.cardemu", track: "internal",
    release_status: "completed", aab:, json_key:, validate_only:,
    skip_upload_metadata/images/screenshots/changelogs: true)`.
  - `validate_only` arrives as a string from the CLI; compare with `"true"`.
- `ios_verify_app_store(key_id, issuer_id, key_filepath, ipa_path?)`
  - `upload_to_app_store(verify_only: true, skip_metadata: true,
    skip_screenshots: true, run_precheck_before_submit: false, force: true)`;
    `upload_to_testflight` has no dry-run mode.
- New `fastlane/Appfile`: `app_identifier("foundation.privacybydesign.irmamob")`,
  `package_name("org.irmacard.cardemu")`, `team_id(...)` (take the team ID from the
  Xcode project).
- `fastlane/README.md`: document the three lanes.

Check: `bundle exec fastlane lanes` lists them; `ruby -c fastlane/Fastfile`.

### 2. Upload steps in `delivery.yml`

In `build-app-ios-beta`, after the Sentry step (so a failed upload still leaves the
IPA and symbols on the run):

```yaml
- name: Decode App Store Connect API key
  env:
    APP_STORE_CONNECT_KEY: ${{ secrets.APP_STORE_CONNECT_KEY }}
  run: echo "$APP_STORE_CONNECT_KEY" | base64 --decode > ./fastlane/profiles/app_store_connect_key.p8
- name: Upload to TestFlight
  env:
    KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
    ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
  run: >
    bundle exec fastlane ios_upload_testflight
    key_id:"$KEY_ID" issuer_id:"$ISSUER_ID"
    key_filepath:profiles/app_store_connect_key.p8
```

Same in `build-app-android-beta` with `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` →
`profiles/play_service_account.json` → `android_upload_play_store`.

Pass secrets through `env:` instead of `${{ }}` inside `run:`, so the zizmor check in
Status checks stays clean. Remove the stale comment on `build-app-android-beta`
("only signed with a development key"): it is signed with the upload key.

### 3. Version check

Today: `git diff -U0 $BEFORE_SHA -- yivi_app/pubspec.yaml | grep '^+version: …'`.
This fires on any change to the version line, including a semver-only change that
both stores would refuse (same build number), and on a diff against a missing
`before` (force push).

Replace with Idem's check: read the `+N` build number before and after, and pass only
when both are readable and `after > before`. Keep the job's output name
(`version-changed`) so the beta jobs need no change.

### 4. Dry run (`.github/workflows/dry-run-distribution.yml`)

Same shape as Idem: `workflow_dispatch` (choice `both | ios | android`) and
`workflow_call`. It builds the beta flavor with the `app-store-beta` /
`android-beta` environments and runs `ios_verify_app_store` and
`android_upload_play_store validate_only:true`. Nothing is published and no build
number is used.

Difference from Idem: our app needs the Go bridge. Artifacts from the calling run
are available to a `workflow_call` run, but not to a manual run. So the dry run
builds the bridge itself (`ios_build_irmagobridge` / `android_build_irmagobridge`)
in its own jobs, instead of downloading `irmagobridge-*`.

Built as manual only (`workflow_dispatch`), see open question 2. Making it automatic
later means adding `workflow_call` and calling it from `delivery.yml` when
`version-changed != 'true'`, with `secrets: inherit`.

### 5. Documentation (`.github/workflows/README.md`)

Under Delivery: what uploads where, that promotion is manual, the dry run, and the
new secrets (below).

### 6. Store-side setup (someone with admin access to the stores and GitHub)

- **App Store Connect:** an API key with the App Manager role. Add to environment
  `app-store-beta`: `APP_STORE_CONNECT_KEY` (base64 of the `.p8`),
  `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`. An API key avoids an
  Apple ID with 2FA in CI.
- **Google Play:** a service account in a Google Cloud project, invited in the Play
  Console with release permissions for `org.irmacard.cardemu` (it takes a while to
  propagate). Add to environment `android-beta`: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
  (base64 of the key file).
- Confirm that the keystore in `android-beta` holds the upload key Play has
  registered for this app; otherwise Play refuses the bundle.

### 7. First runs

1. Manual dry run (`both`) from the Actions tab on the branch → both validations
   green.
2. Merge. The next release PR that raises the build number uploads for real; check
   that the build appears in TestFlight (after Apple's processing) and on the Play
   internal track.

## Order of work

1 → 3 → 2 → 4 → 5 in one PR (they can't be tested without the secrets anyway). Step 6
can happen in parallel and must be done before step 7.

## Open questions

1. **Who sets up the store credentials** (step 6), and does an App Store Connect API
   key / Play service account already exist for Yivi?
2. **Dry run on every merge or only manual?** Idem runs it on every non-release
   merge. For irmamobile that is two more app builds (iOS on macOS, Android) and
   two more Go bridge builds per merge to `master`. Recommendation: manual only, plus once on
   the release PR's branch before merging; switch to automatic later if uploads
   break often.
3. **Release status on Play internal:** `completed` (testers get it straight away,
   like Idem) or `draft` (someone presses release)? Recommendation: `completed`.
