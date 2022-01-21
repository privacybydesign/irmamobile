# irmamobile

## Authentication made easy, privacy-friendly, and secure

IRMA offers a privacy-friendly, flexible and secure solution to many authentication problems,
putting the user in full control over his/her data.

The IRMA app manages the user's IRMA cards containing personal data. It can receive new cards, selectively disclose data contained in the user's cards to others, and
attaching data to signed statements. These data can be relevant properties, such as: "I am over 18", "my name is
..." and "I am entitled to access ....". They are only stored on the user's device and nowhere else.

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get it on Google Play"
     height="80">](https://play.google.com/store/apps/details?id=org.irmacard.cardemu)
[<img src="https://privacybydesign.foundation/images/app-store-badge-padded.png"
     alt="Get it on Apple App Store"
     height="80">](https://itunes.apple.com/nl/app/irma-authentication/id1294092994)
[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/org.irmacard.cardemu/)

<img src="https://irma.app/docs/assets/irmamobile/ios_pin.png" width="200" alt="Screenshot of the IRMA app on iOS, showing the PIN screen" /> &nbsp;
<img src="https://irma.app/docs/assets/irmamobile/android_wallet.png" width="200" alt="Screenshot of the IRMA app on Android, showing the wallet screen with three cards" /> &nbsp;
<img src="https://irma.app/docs/assets/irmamobile/ios_wallet_expanded.png" width="200" alt="Screenshot of the IRMA app on iOS, showing the wallet screen with a card expanded" />
<img src="https://irma.app/docs/assets/irmamobile/android_disclosure.png" width="200" alt="Screenshot of the IRMA app on Android, showing the data disclosure screen" /> &nbsp;

## Development setup

* Clone the project

      git clone --recursive git@github.com:privacybydesign/irmamobile.git

* If your forgot to include `--recursive` in your `git clone`, make sure to init and update the submodules:

      cd irmamobile
      git submodule init
      git submodule update

* Install Java development kit. Java 11 _should_ work. Java 8 is not supported anymore.

      # On Debian / Ubuntu
      apt install openjdk-11-jdk

      # On MacOS
      # TODO: Install via `brew install openjdk@11`, but how to replace system Java?

* Install the Android SDK tools by going to the [Android developer download page](https://developer.android.com/studio/).
  Make sure to install the build-tools and platform for Android >= 28. In addition
  to the SDK platform, the following SDK tools need to be installed:
  * Android SDK Command-line Tools
  * Android SDK Build-Tools
  * Android SDK Platform-Tools
  * NDK version 21.x (version 22.x is not supported by `gomobile` yet)
  * CMake

  If you're using the SDK Manager of Android Studio: you can find specific versions for Build-Tools
  by enabling the option `Show Package Details`.

* Update your environment. You installed the Android SDK in the previous step, but
  you will still need to update your `PATH` to make sure you can access the utilities provided and to
  make sure that flutter keeps working, you will need to export an `ANDROID_HOME` environment
  variable:

      echo 'export ANDROID_HOME="/YOUR/PATH/TO/android-sdk"' >> "$HOME/.bashrc"
      echo 'export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"' >> "$HOME/.bashrc"

* Download Flutter from the [download page](https://flutter.dev/docs/get-started/install) and
  follow their installation steps. Make sure to update your $PATH again.

* Run `flutter doctor` to see what steps remain to get a fully operational development environment
  for flutter (this may include accepting the android licenses). At this point you could also
  download your development environment.

* Install Go from the [Go download page](https://golang.org/dl/) or by using your OS package
  manager.

* Run (somewhere outside of your `irmamobile` checkout) `go get golang.org/x/mobile/cmd/gomobile` to install gomobile and then run `gomobile init`
  to initialize gomobile.

* Create the irmagobridge: `./bind_go.sh`.

* Start an emulator or connect a device via USB and run the flutter project: `flutter run`. You can
  also use Android Studio or Visual Studio Code for this step. On Android, sometimes the build flavor
  is not picked up automatically. This can be identified when the flutter tool cannot
  find the generated apk after building. In this case run `flutter run --flavor alpha`.
  In case you run the flutter project via Android Studio, you
  can specify the build flavor in the run configuration. On iOS, no custom flavor should be specified.

* You can use `flutter run -t` to run different app configurations, for example run `flutter run -t lib/main_prototypes.dart` to start the app in the prototypes menu.

## JSON serialization code

This project uses json_serializer. To re-generate serialization code, run `./codegen.sh`

## Integration tests
_The integration tests are in development, so not all use cases are covered yet._

As preliminary to run the integration tests, you need a fully configured [irmamobile development setup](#development-setup).

### Setting up a keyshare server for testing
The integration tests need a running `irma keyshare server` to test enrollment. You cannot use the production keyshare server for this.

If you don't have access to a remote test environment, you can set up your own keyshare server locally using Docker.
For an explanation on how to do this, you can check the [running instructions of `irmago`](https://github.com/privacybydesign/irmago#running).

### Run locally using an iOS/Android simulator
First, you have to specify which keyshare server the integration tests should use. This can be done by setting the `SCHEME_URL` or the `SCHEME_PATH` environment variable.

In case you are using a remote test environment, you should specify the issuer scheme URL of its custom scheme using the `SCHEME_URL` environment variable.
To use this option, you need the [`irma` CLI tool](https://github.com/privacybydesign/irmago#installing) to be installed and available in your PATH.

    SCHEME_URL=https://example.com/schememanager/test

If you have a local set-up, you should specify the path to the test configuration of your local keyshare server. For instance, when you are using the Docker set-up from `irmago`:

    SCHEME_PATH=/path/to/irmago/testdata/irma_configuration/test

By default, the script runs all integration tests. The tests can be started in the following way:

      # For an iOS testing device/simulator
      dart test_driver/main.dart
      # For an Android testing device/simulator
      adb reverse tcp:8080 tcp:8080
      dart test_driver/main.dart --flavor=alpha

To run a specific set of integration tests, you can override the test target using the `--target` command line argument.

      dart test_driver/main.dart --target=integration_test/issuance_test.dart

Note: we currently use `flutter drive` to run the integration tests, because `flutter test` does not allow us to specify a `--flavor` on Android.
Due to this, the tests sometimes hang when "attempting to resume isolate" on Android. For now, the easiest work-around is to run the tests a second time then.

### Run on Android natively

To natively run the integration tests on Android, you can use the command below. It uses the configuration from the `irma_configuration` directory.
You have to manually set the `irma_configuration` for testing. When using the default set-up, the tests will fail because the `pbdf` production scheme cannot be used.

      flutter pub get
      (cd android && ./gradlew app:connectedAlphaDebugAndroidTest -Ptarget=`pwd`/../integration_test/test_all.dart)

You can also manually build APKs for testing.

      flutter pub get
      (cd android && ./gradlew app:assembleAndroidTest)
      (cd android && ./gradlew app:assembleAlphaDebug -Ptarget=`pwd`/../integration_test/test_all.dart)

You can use those APKs for testing with services like [Google Firebase](https://flutter.dev/docs/testing/integration-tests#uploading-an-android-apk).
You can also run them locally using the following commands:

      adb install build/app/outputs/apk/alpha/debug/app-alpha-debug.apk
      adb install build/app/outputs/apk/androidTest/alpha/debug/app-alpha-debug-androidTest.apk
      adb shell am instrument -w -r foundation.privacybydesign.irmamobile.alpha.test/androidx.test.runner.AndroidJUnitRunner

## Troubleshooting

* Have you checked out the two submodules of this repository? If `find ./irma_configuration` is empty, this is the case.
* If something has changed in the `irmagobridge` or in `irmago` then rerunning `./bind_go.sh` is required.
* In case you get the warning that the `ndk-bundle` cannot be found, please set the `ANDROID_NDK_HOME`
  environment variable to the right ndk version directory. These version directories can be found in `$ANDROID_HOME/ndk`.
  For example, you have to specify `export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/21.1.6352462`.
  You can also make a symlink in `ANDROID_HOME` by doing
  `ln -s $ANDROID_HOME/ndk/<NDK_VERSION> $ANDROID_HOME/ndk-bundle`. In here `<NDK_VERSION>` should be replaced
  with the NDK version you want to use.
* When you get an error related to `x_cgo_inittls` while running `./bind_go.sh`, you probably use an incorrect version of the Android NDK (see above) or your Go version is too old.
* When you are working with Windows, you need to manually make a symlink between the configuration folders. You can do this by opening a terminal as administrator and use the following command: `mklink /d .\android\app\src\main\assets\irma_configuration .\irma_configuration`.
* When you are building for iOS using XCode and you get `Dart Error: Can't load Kernel binary: Invalid kernel binary format version.`, then likely your Flutter cache is corrupted. You can empty and reload the Flutter cache in the following way:
```shell
pushd $(which flutter)/../
rm -rf ./cache
flutter doctor
flutter precache --ios
popd
flutter pub get
cd ./ios && pod install
```
