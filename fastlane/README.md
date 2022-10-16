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
All actions that make iOS app builds require an app provisioning profile and the corresponding PKCS#12 certificate bundle.
Therefore, these actions require the parameters `provisioning_profile_path`, `certificate_path` and `certificate_password`.

Below we describe how to generate these assets. This can only be done by users with the 'Admin' role or
the 'App Manager' role with access to certificates, identifiers and profiles in Apple App Store Connect.
Generated provisioning profiles are valid for one year.

 1. Go to the ./fastlane directory in irmamobile
 2. Run `mkdir -p ./fastlane/profiles && cd ./fastlane/profiles`
 3. Run `openssl req -nodes -newkey rsa:2048 -keyout apple_distribution.key -out apple_distribution.csr`
 4. Follow the instruction prompts
 5. Upload the CSR to Apple: go to https://developer.apple.com/account/resources/certificates/list, press the '+' sign
    and choose "iOS Distribution (App Store and Ad Hoc)"
 6. When finished, download the .cer file and save it to the directory created in step 2 as `apple_distribution.cer`
 7. Convert the .cer file to a .pem file:
    `openssl x509 -in apple_distribution.cer -inform DER -out apple_distribution.pem -outform PEM`
 8. Convert the .pem to a .p12 and choose the certificate password:
    `openssl pkcs12 -export -inkey apple_distribution.key -in apple_distribution.pem -out apple_distribution.p12`
 9. You can now create a provisioning profile: go to https://developer.apple.com/account/resources/profiles/list,
    press the '+' sign and follow the instructions
 10. When finished, download the provisioning profile and save it to the directory created in step 2
 11. In case you need to upload the assets to a secret vault, then you need to encode the files with base64,
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

### alpha_resign

```sh
[bundle exec] fastlane alpha_resign
```

Resigns the alpha flavor APKs in the `build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    ANDROID_SIGN_KEYSTORE=...
    ANDROID_SIGN_KEY_ALIAS=...
    ANDROID_SIGN_STORE_PASSWORD=...
    ANDROID_SIGN_KEY_PASSWORD=...

### beta_resign

```sh
[bundle exec] fastlane beta_resign
```

Resigns the beta flavor APKs in the `build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    ANDROID_SIGN_KEYSTORE=...
    ANDROID_SIGN_KEY_ALIAS=...
    ANDROID_SIGN_STORE_PASSWORD=...
    ANDROID_SIGN_KEY_PASSWORD=...

### alpha_build

```sh
[bundle exec] fastlane alpha_build
```

Builds the alpha flavor for both iOS and Android, including the irmagobridge.
The unsigned Android APK and the signed iOS IPA files are written to
`build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    SENTRY_DSN_ALPHA=...

Furthermore, it assumes the iOS provisioning profile is manually set in Xcode.
If this is not the case, consider to use the `ios_build_app` action instead.

### beta_build

```sh
[bundle exec] fastlane beta_build
```

Builds the beta flavor for both iOS and Android, including the irmagobridge.
The unsigned Android APK and the signed iOS IPA files are written to the
`build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    SENTRY_DSN_PROD=...

Furthermore, it assumes the iOS provisioning profile is manually set in Xcode.
If this is not the case, consider to use the `ios_build_app` action instead.

### alpha_android_build

```sh
[bundle exec] fastlane alpha_android_build
```

Builds the alpha flavor for both Android only, including the irmagobridge.
The unsigned Android APK files are written to the
`build` directory (so `fastlane/build` from the repository's root).
This action expects the following parameters as environment variables:

    SENTRY_DSN_ALPHA=...

### beta_android_build

```sh
[bundle exec] fastlane beta_android_build
```

Builds the beta flavor for both iOS and Android, including the irmagobridge.
The unsigned Android APK files are written to the
`build` directory (so `fastlane/build` from the repository's root).
This action expects the following parameters as environment variables:

    SENTRY_DSN_PROD=...

### android_build_app

```sh
[bundle exec] fastlane android_build_app flavor:<VALUE> target_platform:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android APK for the requested flavor and target platform. This action
assumes the android_build_irmagobridge action has been run first.
The unsigned Android APK is written to the
`build` directory (so `fastlane/build` from the repository's root).

The `flavor` parameter accepts the values `alpha` or `beta`.

The `target_platform` parameter accepts the values `android-arm`, `android-arm64` or `android-x64`.

### alpha_ios_build

```sh
[bundle exec] fastlane alpha_ios_build
```

Builds the alpha flavor for iOS only, including the irmagobridge.
The signed iOS IPA file is written to the
`build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    SENTRY_DSN_ALPHA=...

Furthermore, it assumes the iOS provisioning profile is manually set in Xcode.
If this is not the case, consider to use the `ios_build_app` action instead.

### beta_ios_build

```sh
[bundle exec] fastlane beta_ios_build
```

Builds the beta flavor for iOS only, including the irmagobridge.
The signed iOS IPA file is written to the
`build` directory (so `fastlane/build` from the repository's root).

This action expects the following parameters as environment variables:

    SENTRY_DSN_PROD=...

Furthermore, it assumes the iOS provisioning profile is manually set in Xcode.
If this is not the case, consider to use the `ios_build_app` action instead.

### ios_build_app

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE>
```

Builds the requested flavor for iOS only. This action
assumes the ios_build_irmagobridge action has been run first.
The signed iOS IPA file is written to the
`build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the paths to the app provisioning profile and the corresponding PKCS#12 certificate bundle
that should be used to provision and sign the build.

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> provisioning_profile_path:<VALUE> certificate_path:<VALUE> certificate_password:<VALUE>
```

The `flavor` parameter accepts the values `alpha` or `beta`.

The `alpha` flavor expects an ad-hoc provisioning profile and the `beta` flavor an app-store provisioning profile.
More information on how to achieve app provisioning profiles can be found [above](#apple-provisioning-profiles).

### android_build_irmagobridge

```sh
[bundle exec] fastlane android_build_irmagobridge
```



### ios_build_irmagobridge

```sh
[bundle exec] fastlane ios_build_irmagobridge
```



----

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
