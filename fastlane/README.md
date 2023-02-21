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
Therefore, these actions require the parameters `certificate_path`, `certificate_password` and either
`api_key_filepath`, `api_key_id` and `api_issuer_id` (to download the provisioning
profile automatically using the App Store Connect API) or `provisioning_profile_path` (to manually pass it).
In the latter case, if you later edit the provisioning profile in App Store Connect, then you need to update
the provisioning profile manually.

Below we describe how to generate these assets. This can only be done by users with the 'Admin' role or
the 'App Manager' role with access to certificates, identifiers and profiles in Apple App Store Connect.
Generated provisioning profiles are valid for one year. If you already have a valid certificate bundle, and you only
want to generate a new provisioning profile, you can skip step 1 through 7.

 1. Go to the ./fastlane directory in irmamobile.
 2. Run `mkdir -p ./profiles && cd ./profiles`
 3. Run `openssl req -nodes -newkey rsa:2048 -keyout apple_distribution.key -out apple_distribution.csr`.
 4. Upload the CSR to Apple: go to https://developer.apple.com/account/resources/certificates/list, press the '+' sign
    and choose "iOS Distribution (App Store and Ad Hoc)".
 5. When finished, download the .cer file and save it to the directory created in step 2 as `apple_distribution.cer`
 6. Convert the .cer file to a .pem file:
    `openssl x509 -in apple_distribution.cer -inform DER -out apple_distribution.pem -outform PEM`.
 7. Convert the .pem to a .p12 and choose the certificate password:
    `openssl pkcs12 -export -inkey apple_distribution.key -in apple_distribution.pem -out apple_distribution.p12`.
    The generated `.p12` file and the corresponding password are the input values for the
    `certificate_path` and `certificate_password` parameters.
 8. You can now create a provisioning profile: go to https://developer.apple.com/account/resources/profiles/list,
    press the '+' sign and follow the instructions.
 9. In case you want to use the `provisioning_profile_path` parameter, download the provisioning profile and save it
    to the directory created in step 2. If you want to use the `api_key_filepath` parameter, you can skip this step.
 10. In case you need to upload the assets to a secret vault, then you need to encode the files with base64,
     i.e. `cat apple_distribution.p12 | base64 > apple_distribution.p12.base64`.

When generating keys for CI platforms, it's recommended to protect the certificate bundle as a secret in
protected deployment environments. In this way, you prevent that development builds get signed.

Don't forget to delete the local file copies after you've uploaded the profiles and certificates to your CI's secret vault.

Note: provisioning profiles can only be used to sign app builds. To upload the builds to Apple,
you additionally need your personal App Store Connect account with the right permissions.
Uploading can be done using [Transporter for MacOS](https://apps.apple.com/us/app/transporter/id1450874784?mt=12).

# Android signing/upload keys
The artifacts produced by the `android_build_apk` and the `android_build_appbundle` actions need to be signed in order
to distribute them. For the Google Play Store, you need an app bundle signed with the right upload key.
The corresponding certificate needs to be registered with Google. This upload key is also used as signing key for
Android Code Transparency. For ad-hoc APKs, artifacts are signed using regular APK signing.
The `android_build_apk` and the `android_build_appbundle` actions have built-in support for signing.
The key should be given as Java Keystore and can be passed using the `keystore_path`, `key_alias`, `keystore_password`
and `key_password` parameters.

Below we describe how you can generate a Java Keystore for signing.

 1. Specify a key name, i.e. `KEY_ALIAS=upload-key`
 2. Run `keytool -genkey -alias $KEY_ALIAS -keyalg RSA -keystore $KEY_ALIAS.jks -keysize 4096 -validity 10000`
 3. If you need to register the key as upload key to Google Play, you can generate the certificate in the following way:
    `keytool -export -rfc -keystore $KEY_ALIAS.jks -alias $KEY_ALIAS -file $KEY_ALIAS.pem`
 4. In case you need to upload the assets to a secret vault, then you need to encode the files with base64,
    i.e. `cat $KEY_ALIAS.jks | base64 > $KEY_ALIAS.jks.base64`

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

### android_build

```sh
[bundle exec] fastlane android_build flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android AAB for the requested flavor.
The AAB is written to the `build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the key properties of the upload key that should be used to sign the build.
This key is also used to sign the app bundle's code transparency file.

```sh
[bundle exec] fastlane android_build flavor:<VALUE> sentry_dsn:<VALUE> keystore_path:<VALUE> key_alias:<VALUE> keystore_password:<VALUE> key_password:<VALUE>
```

The `flavor` parameter accepts the values `alpha` or `beta`.

### android_build_irmagobridge

```sh
[bundle exec] fastlane android_build_irmagobridge
```

Builds the irmagobridge for Android.

### android_build_apk

```sh
[bundle exec] fastlane android_build_apk flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android APK for the requested flavor. Only a universal build is included. Check the `android_build`
or the `android_build_appbundle` action if you want to build for the Google Play Store.
This action assumes the `android_build_irmagobridge` action has been run first.
The Android APK is written to the `build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the key properties of the signing key that should be used.

```sh
[bundle exec] fastlane android_build_apk flavor:<VALUE> sentry_dsn:<VALUE> keystore_path:<VALUE> key_alias:<VALUE> keystore_password:<VALUE> key_password:<VALUE>
```

The `flavor` parameter accepts the values `alpha` or `beta`.

### android_build_appbundle

```sh
[bundle exec] fastlane android_build_appbundle flavor:<VALUE> sentry_dsn:<VALUE>
```

Builds the Android AAB for the requested flavor.
This action assumes the `android_build_irmagobridge` action has been run first.
Check the `android_build` action if you want to do a full build.
The AAB is written to the `build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the key properties of the upload key that should be used to sign the build.
This key is also used to sign the app bundle's code transparency file.

```sh
[bundle exec] fastlane android_build_appbundle flavor:<VALUE> sentry_dsn:<VALUE> keystore_path:<VALUE> key_alias:<VALUE> keystore_password:<VALUE> key_password:<VALUE>
```

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

Optionally, you can specify the following for extra functionality:

 - You can specify which iOS distribution certificate should be used to sign the build.
   The path to the PKCS#12 certificate bundle of the iOS distribution key can be specified using the `certificate_path`
   parameter. The certificate bundle's password can be specified using the `certificate_password` parameter.

 - You can specify which provisioning profile should be used to provision the app. To automatically fetch
   the right provisioning profile from the App Store Connect API based on the requested flavor and iOS distribution certificate,
   you can use the `api_key_filepath`, `api_key_id` and `api_issuer_id` parameters. More information about this
   mechanism can be found [here](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).
   You can also supply a provisioning profile manually by using the `provisioning_profile_path` parameter.
   The `alpha` flavor expects an ad-hoc provisioning profile and the `beta` flavor an app-store provisioning profile.

If file path are relative, then it is evaluated using the
fastlane directory as base (so `./fastlane` from the repository's root).

More information on how to generate distribution certificates and provisioning profiles can be found [above](#apple-provisioning-profiles).

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> api_key_filepath:<VALUE> api_key_id:<VALUE> api_issuer_id:<VALUE> certificate_path:<VALUE> certificate_password:<VALUE>
[bundle exec] fastlane ios_build_app flavor:<VALUE> provisioning_profile_path:<VALUE> certificate_path:<VALUE> certificate_password:<VALUE>
```

Alternatively, you can run this action without an app provisioning profile by disabling the IPA export.
This can be useful for testing purposes if you don't have access to the keys.

```sh
[bundle exec] fastlane ios_build_app flavor:<VALUE> export:false
```

The `flavor` parameter accepts the values `alpha` or `beta`.

----

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
