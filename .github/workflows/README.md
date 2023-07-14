# GitHub Actions workflows

We currently have two workflows. The workflows use our Fastlane scripts. More details about the functioning of the Fastlane
scripts can be found in the [README](../../fastlane/README.md).

## Status checks
This workflow checks whether a change passes all our quality gates.

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
- `GCLOUD_SERVICE_KEY`: Google Firebase service account JSON key (for Device Test Lab access).

## Delivery
This workflow generates distribution app builds. It generates iOS builds (IPA) and Android builds (APK and App Bundle).

For iOS, an ad-hoc build is made on every merge to `master` using the alpha app ID, and an app-store build is made on every
version change in `pubspec.yaml` using the production app ID.

For Android, an APK and App Bundle are made on every merge to `master` for both the `alpha` and the `beta` flavor, being signed
with a alpha app signing key (different to production). On every version change in `pubspec.yaml` an App Bundle
is made using the upload key that is registered with Google.

### Secrets
Below a list of the secrets that are needed. The secrets should be uploaded as [environment secrets](https://github.com/privacybydesign/irmamobile/settings/environments).

Secrets for the `android-alpha` (Android master builds) and `android-beta` (Android production builds) environments:

- `ANDROID_SIGNING_KEYSTORE`: Base64 encoded Android signing/upload keystore, check the [Fastlane docs](../../fastlane/README.md#android-signingupload-keys) for generating instructions. For the `android-alpha` environment it concerns a signing keystore and for the `android-beta` environment an upload keystore.
- `ANDROID_SIGNING_KEYSTORE_PASSWORD`: password of the Android keystore (see above).
- `SENTRY_DSN`: Sentry DSN for error reporting.

Secrets for the `ad-hoc-alpha` (iOS master/alpha builds) and the `app-store-beta` (iOS production builds) environments:

- `APPLE_DISTRIBUTION_CERTIFICATE`: Base64 encoded PKCS12 certificate of the Apple distribution certificate, check the [Fastlane docs](../../fastlane/README.md#generating-new-certificates) for generating instructions. In both the `ad-hoc-alpha` and `app-store-beta` environment the same distribution certificate
should be uploaded, because there only is one. This certificate expires every year.
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`: password of the Apple development certificate (see above).
- `APPLE_PROVISIONING_PROFILE`: Base64 encoded Apple provisioning profile that is linked to the distribution certificate (see above). In the `ad-hoc-alpha` environment the `GitHub Actions ad hoc alpha` ad-hoc provisioning profile should be uploaded (linked to `foundation.privacybydesign.irmamob.alpha`) and in the `app-store-beta` enviroment the `GitHub Actions app store beta` app store provisioning profile should be uploaded (linked to `foundation.privacybydesign.irmamob`). These should be renewed when the distribution certificate is being renewed.
This should be renewed when the development certificate is being renewed.
- `SENTRY_DSN`: Sentry DSN for error reporting.
