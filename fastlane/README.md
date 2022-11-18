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
The `ios_build_app` and the `ios_build_integration_test` actions needs the app's provisioning profile and the
corresponding PKCS#12 certificate bundle. Therefore, these actions require the parameters
`provisioning_profile_path`, `certificate_path` and `certificate_password`.

There are two types of certificate bundles: development certificates and distribution certificates.
Development certificates are bound to individual developers and can be used to build for the developer's own iOS device.
The distribution certificate belongs to the organization and is needed for ad-hoc and app store builds.
For integration tests builds that you want to upload to Google Firebase, using a development certificate is sufficient.

Note: provisioning profiles can only be used to sign app builds. To upload the builds to Apple,
you additionally need your personal App Store Connect account with the right permissions.
Uploading can be done using [Transporter for MacOS](https://apps.apple.com/us/app/transporter/id1450874784?mt=12).

## Generating new certificates
Below we describe how to generate these assets. For distribution certificates, this can only be done by users with the
'Admin' role or the 'App Manager' role with access to certificates, identifiers and profiles in Apple App Store Connect.
For development certificates, the 'Developer' role with access to certificates, identifiers and profiles fulfills.

Generated certificates and the provisioning profiles linked it are valid for one year. For ad-hoc
provisioning profiles you might want to refresh the provisioning profiles throughout the year to add or
remove devices. More information about adding and updating ad-hoc provisioning profiles can be found [here](#ad-hoc-provisioning-profiles).

 1. Go to the ./fastlane directory in irmamobile
 2. Run `mkdir -p ./profiles && cd ./profiles`
 3. Choose a name for your new certificate, i.e. `KEY_NAME=apple_distribution` or `KEY_NAME=apple_development`
 4. Run `openssl req -nodes -newkey rsa:2048 -keyout $KEY_NAME.key -out $KEY_NAME.csr`
 5. Upload the CSR to Apple: go to https://developer.apple.com/account/resources/certificates/list, press the '+' sign
    and choose "iOS Distribution (App Store and Ad Hoc)" for a distribution certificate or "iOS App Development"
    for a development certificate.
 6. When finished, download the .cer file and save it to the directory created in step 2 as `$KEY_NAME.cer`
 7. Convert the .cer file to a .pem file:
    `openssl x509 -in $KEY_NAME.cer -inform DER -out $KEY_NAME.pem -outform PEM`
 8. Convert the .pem to a .p12 and choose the certificate password:
    `openssl pkcs12 -export -inkey $KEY_NAME.key -in $KEY_NAME.pem -out $KEY_NAME.p12`
 9. You can now create a provisioning profile: go to https://developer.apple.com/account/resources/profiles/list,
    press the '+' sign and follow the instructions
 10. When finished, download the provisioning profile and save it to the directory created in step 2
 11. In case you need to upload the assets to a secret vault, then you need to encode the files with base64,
     i.e. `cat $KEY_NAME.p12 | base64 > $KEY_NAME.p12.base64`

When generating distribution certificates for CI platforms, it's recommended to protect the certificate bundle as a secret in
protected deployment environments. In this way, you prevent that development builds get signed.

Don't forget to delete the local file copies after you've uploaded the profiles and certificates to your CI's secret vault.

## Ad-hoc provisioning profiles
Ad-hoc provisioning profiles are needed when you want to distribute a build of your app without uploading it to Apple.
This can be useful for early testing. For ad-hoc app distribution on iOS you need to add a whitelist of UDIDs on which
the build may be installed. If you want to add extra devices, you need to make a new app build.

Ad-hoc provisioning profiles are required when using Google Firebase App Distribution to spread
development builds to your team.

For ad-hoc provisioning profiles you need an underlying Apple distribution certificate. Check the [instructions above](#generating-new-certificates)
how to generate this. You can add new or renew existing ad-hoc provisioning profiles with an existing Apple distribution certificate.

Below we describe how you can (re)new ad-hoc provisioning profiles.

 1. Go to developer.apple.com and login using your Apple Account. This can only be done by users with the 'Admin' role
    or the 'App Manager' role with access to certificates, identifiers and profiles in Apple App Store Connect.
 2. Select 'Devices'.
 3. Ensure all devices you want to build for are present in the overview. This can be realised in different ways.
    Missing users can be added as a user the organization's Apple Developer Account. The devices linked to the Apple
    accounts of all members will appear in the overview automatically. It is also possible to add devices manually using
    the device's UDID. For this, press the '+' sign. You then need to enter the UDIDs of the devices you want to add.
    This can either be done manually using the fields on the left or in batches using 'Register Multiple Devices' on the
    right. Google Firebase App Distribution automatically collects the UDID of all devices in the distribution list.
    The list with UDIDs can be downloaded there as CSV for uploading via 'Register Multiple Devices'. Users can also manually
    find their UDID using the [Apple Configurator](https://support.apple.com/nl-nl/apple-configurator) tool.
 4. Select the 'Profiles' tab on the left.
 5. Select the ad-hoc provisioning profile you want to edit or make a new one by pressing the '+' sign.
 6. In case you choose to edit an existing profile, press 'Edit'.
 7. Select all devices you want to the profile and confirm.
 8. Download the new provisioning profile. Existing profiles are not updated automatically. The new profile should
    be downloaded and installed again on all relevant places. When you use the provisioning profile in CI platforms,
    then you should update the corresponding secret in your CI's secret vault.

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

### ios_build_integration_test

```sh
[bundle exec] fastlane ios_build_integration_test
```

Builds the iOS XCTests to run the Flutter integration tests on iOS natively.
All files are bundled together in a ZIP.
This action assumes the `ios_build_irmagobridge` action has been run first.
The ZIP is written to the `build` directory (so `fastlane/build` from the repository's root).

Optionally, you can specify the paths to the app provisioning profile and the corresponding PKCS#12 certificate bundle
that should be used to provision and sign the build. If the given path is relative, then it is evaluated using the
fastlane directory as base (so `./fastlane` from the repository's root).

```sh
[bundle exec] fastlane ios_build_integration_test provisioning_profile_path:<VALUE> certificate_path:<VALUE> certificate_password:<VALUE>
```

----

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
