fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

Furthermore, you need to follow the development setup instructions in the repository root directory's README.
Setup scripts for CI platforms can be found in the _ci_scripts_ directory.

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Apple provisioning profiles
The `ios_build_app` action needs the app's provisioning profile and the corresponding PKCS#12 certificate bundle.
Therefore, these actions require the parameters `provisioning_profile_path`, `certificate_path` and `certificate_password`.

Below we describe how to generate these assets. This can only be done by users with the 'Admin' role or
the 'App Manager' role with access to certificates, identifiers and profiles in Apple App Store Connect.
Generated provisioning profiles are valid for one year.

 1. Go to the ./fastlane directory in irmamobile
 2. Run `mkdir -p ./profiles && cd ./profiles`
 3. Run `openssl req -nodes -newkey rsa:2048 -keyout apple_distribution.key -out apple_distribution.csr`
 4. Upload the CSR to Apple: go to https://developer.apple.com/account/resources/certificates/list, press the '+' sign
    and choose "iOS Distribution (App Store and Ad Hoc)"
 5. When finished, download the .cer file and save it to the directory created in step 2 as `apple_distribution.cer`
 6. Convert the .cer file to a .pem file:
    `openssl x509 -in apple_distribution.cer -inform DER -out apple_distribution.pem -outform PEM`
 7. Convert the .pem to a .p12 and choose the certificate password:
    `openssl pkcs12 -export -inkey apple_distribution.key -in apple_distribution.pem -out apple_distribution.p12`
 8. You can now create a provisioning profile: go to https://developer.apple.com/account/resources/profiles/list,
    press the '+' sign and follow the instructions
 9. When finished, download the provisioning profile and save it to the directory created in step 2
 10. In case you need to upload the assets to a secret vault, then you need to encode the files with base64,
     i.e. `cat apple_distribution.p12 | base64 > apple_distribution.p12.base64`

When generating keys for CI platforms, it's recommended to protect the certificate bundle as a secret in
protected deployment environments. In this way, you prevent that development builds get signed.

Don't forget to delete the local file copies after you've uploaded the profiles and certificates to your CI's secret vault.

Note: provisioning profiles can only be used to sign app builds. To upload the builds to Apple,
you additionally need your personal App Store Connect account with the right permissions.
Uploading can be done using [Transporter for MacOS](https://apps.apple.com/us/app/transporter/id1450874784?mt=12).

# Available Actions

### lint

```sh
[bundle exec] fastlane lint
```

Checks the code quality of the project.

### unit_test

```sh
[bundle exec] fastlane unit_test
```

Checks whether all unit tests pass.

### android_resign

```sh
[bundle exec] fastlane android_resign flavor:<VALUE> keystore_path:<VALUE> key_alias:<VALUE> keystore_password:<VALUE> key_password:<VALUE>
```

Resigns the APKs in the `build` directory (so `fastlane/build` from the repository's root) for the requested flavor.

### android_build

```sh
[bundle exec] fastlane android_build flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android APKs for the requested flavor. The APKs are split on target platform and a universal build is included.
The unsigned Android APKs are written to the `build` directory (so `fastlane/build` from the repository's root).

The `flavor` parameter accepts the values `alpha` or `beta`.

### android_build_irmagobridge

```sh
[bundle exec] fastlane android_build_irmagobridge
```

Builds the irmagobridge for Android.

### android_build_app

```sh
[bundle exec] fastlane android_build_app flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android APK for the requested flavor. The APKs are split on target platform and a universal build is included.
This action assumes the `android_build_irmagobridge` action has been run first.
The unsigned Android APKs are written to the `build` directory (so `fastlane/build` from the repository's root).

The `flavor` parameter accepts the values `alpha` or `beta`.

### android_build_integration_test

```sh
[bundle exec] fastlane android_build_integration_test
```

Builds the APKs for Android instrumentation testing to run the Flutter integration tests on Android natively.
This action assumes the `android_build_irmagobridge` action has been run first.
The APKs are written to the `build` directory (so `fastlane/build` from the repository's root).

### ios_build

```sh
[bundle exec] fastlane ios_build flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds an iOS IPA file for the requested flavor.

For all extra parameters, please check the [documentation of `ios_build_app`](#ios_build_app).

### ios_build_irmagobridge

```sh
[bundle exec] fastlane ios_build_irmagobridge
```

Builds the irmagobridge for iOS.

### ios_build_app

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds an iOS IPA file for requested flavor. This action
assumes the `ios_build_irmagobridge` action has been run first.
The signed iOS IPA file is written to the `build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the paths to the app provisioning profile and the corresponding PKCS#12 certificate bundle
that should be used to provision and sign the build. If the given path is relative, then it is evaluated using the
fastlane directory as base (so `./fastlane` from the repository's root).

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> provisioning_profile_path:<VALUE> certificate_path:<VALUE> certificate_password:<VALUE>
```

Alternatively, you can run this action without an app provisioning profile by disabling the IPA export.
This can be useful for testing purposes if you don't have access to the keys.

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> export:false
```

The `flavor` parameter accepts the values `alpha` or `beta`.

The `alpha` flavor expects an ad-hoc provisioning profile and the `beta` flavor an app-store provisioning profile.
More information on how to achieve app provisioning profiles can be found [above](#apple-provisioning-profiles).

### integration_test_ios_build

```
fastlane integration_test_ios_build
```

Builds the iOS XCTests to run the Flutter integration tests on iOS natively.
All files are bundled together in a ZIP.
This action assumes the `ios_build_irmagobridge` action has been run first.
The ZIP is written to the `build` directory (so `fastlane/build` from the repository's root).

----

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
