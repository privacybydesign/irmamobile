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
[<img src="https://privacybydesign.foundation/images/app-store-badge.png"
     alt="Get it on Apple App Store"
     height="52">](https://itunes.apple.com/nl/app/irma-authentication/id1294092994)
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

* Install Java development kit. Java 11 _should_ work, but if your Android development environment is too old, you might need to fall back to Java 8. See troubleshooting on how to install Java 8 under Debian/Ubuntu or MacOS.

      # On Debian / Ubuntu
      apt install openjdk-11-jdk

      # On MacOS
      # TODO: Install via `brew install openjdk@11`, but how to replace system Java?

* Install the Android SDK tools by going to the [Android developer download page](https://developer.android.com/studio/).
  You may just want to install the Command line tools only if you are not going to use Android
  Studio. If you are going to use it, you can use the initial setup process of Android Studio to
  setup the SDK. Make sure to install the build-tools and platform for Android >= 28. In addition
  to the SDK platform, the following SDK tools need to be installed:
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

## Troubleshooting

* Have you checked out the two submodules of this repository? If `find ./irma_configuration` is empty, this is the case.
* If something has changed in the `irmagobridge` or in `irmago` then rerunning `./build_go.sh` is required.
* In case you get the warning that the `ndk-bundle` cannot be found, please set the `ANDROID_NDK_HOME`
  environment variable to the right ndk version directory. These version directories can be found in `$ANDROID_HOME/ndk`.
  For example, you have to specify `export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/21.1.6352462`.
  You can also make a symlink in `ANDROID_HOME` by doing
  `ln -s $ANDROID_HOME/ndk/<NDK_VERSION> $ANDROID_HOME/ndk-bundle`. In here `<NDK_VERSION>` should be replaced
  with the NDK version you want to use.

### Installing Java 8

* Install Java JDK 8, using a package manager or by manually downloading one. Once installed, you
  will also have to set the `JAVA_HOME` environment variable. For a Debian based OS you can use:

      sudo apt install openjdk-8-jdk
      export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
      echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> "$HOME/.bashrc"

  Starting from Debian Buster OpenJDK version 8 is no longer available, but it is currently the
  only version of Java fully supported by the Android SDK. You can use the AdoptOpenJDK community
  apt repository:

       wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
       sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
       sudo apt update
       sudo apt install adoptopenjdk-8-hotspot

  For MacOS, you can use homebrew to install java 8:

      brew cask install adoptopenjdk/openjdk/adoptopenjdk8
      export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
      echo 'export JAVA_HOME=`/usr/libexec/java_home -v 1.8`' >> "$HOME/.bashrc"
