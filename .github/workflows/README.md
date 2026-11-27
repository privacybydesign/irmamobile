# GitHub Actions workflows

The build workflows use our Fastlane scripts. More details about the functioning of the Fastlane
scripts can be found in the [README](../../fastlane/README.md).

## Status checks
This workflow checks whether a change passes all our quality gates. It runs on pull requests, the merge queue, pushes
to `master`, every Monday and on demand. Next to our own Flutter/Fastlane jobs (lint, unit tests, app builds) it
calls the shared workflows from [privacybydesign/github-workflows](https://github.com/privacybydesign/github-workflows):
Go checks for the Go bridge in `yivi_core` (gofmt, go fix, go mod tidy, govulncheck, a race build), dependency review
and workflow lint (actionlint and zizmor over everything in `.github`). The final job, `Status checks passed`, is the
one check to require on `master`.

Third-party actions are pinned to a commit SHA; Dependabot keeps them current.

The Firebase Test Lab integration tests are switched off. Set the repository variable `RUN_FIREBASE_INTEGRATION_TESTS`
to `true` to run them again.

### Secrets
Below a list of the secrets that are needed. The secrets should be uploaded as repository secret to both the
[Actions context](https://github.com/privacybydesign/irmamobile/settings/secrets/actions)
and the [Dependabot context](https://github.com/privacybydesign/irmamobile/settings/secrets/dependabot).
This means you need to upload every secret twice.

- `ANDROID_DEVELOPMENT_SIGNING_KEYSTORE`: Base64 encoded Android keystore for development purposes (dummy key), check the [Fastlane docs](../../fastlane/README.md#android-signingupload-keys) for generating instructions.
- `ANDROID_DEVELOPMENT_SIGNING_KEYSTORE_PASSWORD`: password of the Android keystore (see above).
- `APPLE_DEVELOPMENT_CERTIFICATE`: Base64 encoded PKCS12 certificate of the Apple development certificate, check the [Fastlane docs](../../fastlane/README.md#generating-new-certificates) for generating instructions. This certificate expires every year and is linked to the 'IRMA Beheer' email address.
- `APPLE_DEVELOPMENT_CERTIFICATE_PASSWORD`: password of the Apple development certificate (see above).
- `APPLE_DEVELOPMENT_PROVISIONING_PROFILE`: Base64 encoded Apple provisioning profile that is linked to the development certificate (see above). This should be renewed when the development certificate is being renewed.
- `GCLOUD_PROJECT_NAME`: Google Firebase project name (for Device Test Lab access).
- `GCLOUD_SERVICE_KEY`: Google Firebase service account JSON key (for Device Test Lab access).

## Delivery
This workflow generates distribution app builds. It generates iOS builds (IPA) and Android builds (APK and App Bundle).

For iOS, an ad-hoc build is made on every merge to `master` using the alpha app ID, and an app-store build is made on every
version change in `pubspec.yaml` using the production app ID.

For Android, an APK and App Bundle are made on every merge to `master` for both the `alpha` and the `beta` flavor, being signed
with a alpha app signing key (different to production). On every build number increase in `pubspec.yaml` an App Bundle
is made using the upload key that is registered with Google.

The production builds only run when the build number (the `+N` in `yivi_app/pubspec.yaml`) goes up, because the stores
refuse a build number they have already seen. Changing only the semver does not start them.

### Store upload
The production builds are uploaded to the stores automatically, after they are kept as artifacts of the run (so a
refused upload still leaves a build to download):

- **iOS → TestFlight**, for internal testers only. Giving the build to external testers or sending it to App Store review
  stays a manual step in App Store Connect.
- **Android → the internal track of Google Play.** Promoting it to closed/open testing or production stays a manual step
  in the Play Console. The store listing is never touched.

### Distribution dry run
The `Distribution dry run` workflow (`dry-run-distribution.yml`) is started by hand from the Actions tab, for both
platforms or one. It makes the production builds and has them validated by App Store Connect (`verify_only`) and Google
Play (`validate_only`), without uploading anything or using a build number. Run it before a release, or after changing
certificates, provisioning profiles or store credentials.

### Secrets
Below a list of the secrets that are needed. The secrets should be uploaded as [environment secrets](https://github.com/privacybydesign/irmamobile/settings/environments).

Secrets for the `android-alpha` (Android master builds) and `android-beta` (Android production builds) environments:

- `ANDROID_SIGNING_KEYSTORE`: Base64 encoded Android signing/upload keystore, check the [Fastlane docs](../../fastlane/README.md#android-signingupload-keys) for generating instructions. For the `android-alpha` environment it concerns a signing keystore and for the `android-beta` environment an upload keystore.
- `ANDROID_SIGNING_KEYSTORE_PASSWORD`: password of the Android keystore (see above).
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (only `android-beta`): Base64 encoded JSON key of a Google Cloud service account
that is invited in the Play Console with permission to release `org.irmacard.cardemu` to testing tracks. Used to upload to
the internal track. A new permission can take a while before it works.
- `SENTRY_DSN`: Sentry DSN for error reporting.
- `SENTRY_AUTH_TOKEN`: Sentry auth token that may upload debug files. Used to upload the Dart symbols of the obfuscated build, so the Dart frames of its crash reports are readable in Sentry. Needs the variables `SENTRY_ORG` and `SENTRY_PROJECT` (the slugs of the Sentry organisation and project), and `SENTRY_URL` when Sentry is not at sentry.io. They can be set once as repository variables. As long as the token or one of the two slugs is missing, the upload is skipped with a warning and the symbols are only kept as a build artifact.

Secrets for the `ad-hoc-alpha` (iOS master/alpha builds) and the `app-store-beta` (iOS production builds) environments:

- `APPLE_DISTRIBUTION_CERTIFICATE`: Base64 encoded PKCS12 certificate of the Apple distribution certificate, check the [Fastlane docs](../../fastlane/README.md#generating-new-certificates) for generating instructions. In both the `ad-hoc-alpha` and `app-store-beta` environment the same distribution certificate
should be uploaded, because there only is one. This certificate expires every year.
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`: password of the Apple development certificate (see above).
- `APP_STORE_CONNECT_KEY` (only `app-store-beta`): Base64 encoded `.p8` file of an App Store Connect API key with the
'App Manager' role (App Store Connect → Users and Access → Integrations → Team Keys). Used to upload to TestFlight. A key
is used instead of an Apple ID, so CI needs no 2FA session.
- `APP_STORE_CONNECT_KEY_ID` (only `app-store-beta`): the key ID of that API key.
- `APP_STORE_CONNECT_ISSUER_ID` (only `app-store-beta`): the issuer ID shown above the list of team keys.
- `APPLE_PROVISIONING_PROFILE`: Base64 encoded Apple provisioning profile that is linked to the distribution certificate (see above). In the `ad-hoc-alpha` environment the `GitHub Actions ad hoc alpha` ad-hoc provisioning profile should be uploaded (linked to `foundation.privacybydesign.irmamob.alpha`) and in the `app-store-beta` environment the `GitHub Actions app store beta` app store provisioning profile should be uploaded (linked to `foundation.privacybydesign.irmamob`). These should be renewed when the distribution certificate is being renewed.
- `SENTRY_DSN`: Sentry DSN for error reporting.
- `SENTRY_AUTH_TOKEN`: Sentry auth token that may upload debug files. Used to upload the Dart symbols of the obfuscated build, so the Dart frames of its crash reports are readable in Sentry. Needs the variables `SENTRY_ORG` and `SENTRY_PROJECT` (the slugs of the Sentry organisation and project), and `SENTRY_URL` when Sentry is not at sentry.io. They can be set once as repository variables. As long as the token or one of the two slugs is missing, the upload is skipped with a warning and the symbols are only kept as a build artifact.
