# irmamobile

## Authentication made easy, privacy-friendly, and secure

IRMA offers a privacy-friendly, flexible and secure solution to many authentication problems,
putting the user in full control over his/her data.

The IRMA app manages the user's IRMA attributes: receiving new attributes, selectively disclosing them to others, and
attaching them to signed statements. These attributes can be relevant properties, such as: "I am over 18", "my name is
..." and "I am entitled to access ....". They are only stored on the user's device and nowhere else.

## Development setup

To start developing the irmamobile app you will need to setup a development environment. Most of
the environment can be installed automatically by using the included makefile, but you will have to
do some work yourself, please read the instructions below carefully. If you want to use the included
makefile you will need to install `make` (included in the developer tools on MacOS), `curl`,
`unzip`, `xz-utils` and `tar` yourself.

* Currently only Android is supported
* Setup a `GOPATH` and create a directory for cloning the project into. If you don't yet use go
  then this project includes a make task to install go. You can use any directory as a `GOPATH`,
  although often `$HOME/go` is used (in newer go versions this is the default and you can skip this
  step), like this:

      export GOPATH=$HOME/go
      echo 'export GOPATH=$HOME/go' >> "$HOME/.bashrc"

  You may also want to add the bin directory of your `GOPATH` to your `PATH`:

      export PATH="$GOPATH/bin:$PATH"
      echo 'export PATH="$GOPATH/bin:$PATH"' >> "$HOME/.bashrc"

* Clone the project into your `GOPATH` at `$GOPATH/src/github.com/privacybydesign/irmamobile`.

      git clone git@gitlab.science.ru.nl:irma/irmamobile.git $GOPATH/src/github.com/privacybydesign/irmamobile

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

* Install the Android SDK and flutter by running `make flutter-android-sdk`. Note that this only
  works on Linux and MacOS on x86_64 (amd64) architectures, see the manual instructions below if
  you are not on such an OS/platform. This also applies to the following steps.
* Update your environment. The previous step installed the Android SDK and Flutter SDK for you, but
  you will still need to update your `PATH` to make sure you can access the utilities provided and to
  make sure that flutter keeps working, you will need to export an `ANDROID_HOME` environment
  variable:

      export ANDROID_HOME="$HOME/Android/Sdk"
      export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$HOME/Android/flutter/bin:$PATH"
      echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> "$HOME/.bashrc"
      echo 'export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$HOME/Android/flutter/bin:$PATH"' >> "$HOME/.bashrc"

* Create the irmagobridge: `make irmagobridge-android`. This will use a local go version of no
  global one on your `PATH` is found.
* Start an emulator or connect a device via USB and run the flutter project: `flutter run`. You can
  also use Android Studio or Visual Studio Code for this step.

### Installation without the makefile

If you are running an unsupported OS/Platform combination you can't use the makefile, in that case
you will have to install everything manually, you can do so using these instructions as a general
guideline:

* Run the previous steps up to the step to automatically install flutter.
* Install the Android SDK tools by going to the [android developer download page](https://developer.android.com/studio/).
  You may just want to install the Command line tools only if you are not going to use Android
  Studio. If you are going to use it, you can use the initial setup process of Android Studio to
  setup the SDK. Make sure to install the build-tools and platform for Android >= 28.
* Once the SDK is installed use the SDK manager to install `ndk-bundle`, `cmake` and `lldb`.
* Install an emulator image using the SDK manager if you want to run the project on an emulator.
* Update your environment to make the SDK discoverable by flutter (change the directories if you
  installed to a different location):

      export ANDROID_HOME="$HOME/Android/Sdk"
      export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
      echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> "$HOME/.bashrc"
      echo 'export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"' >> "$HOME/.bashrc"

* Download flutter from the [download page](https://flutter.dev/docs/get-started/install) and
  follow their installation steps.
* Run `flutter doctor` to see what steps remain to get a fully operational development environment
  for flutter (this may include accepting the android licenses). At this point you could also
  download your development environment.
* Install go from the [go download page](https://golang.org/dl/) or by using your OS package
  manager.
* Run `go get golang.org/x/mobile/cmd/gomobile` to install gomobile and then run `gomobile init`
  to initialize gomobile.
* Run `gomobile bind -target android -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge`.
* Start an emulator or connect a device via USB and run the flutter project: `flutter run`. You can
  also use Android Studio or Visual Studio Code for this step.
* Run `flutter run -t lib/main_prototypes.dart` to start the app in the prototypes menu.

## JSON serialization code

This project uses json_serializer. To re-generate serialization code, run the
following commands:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter format --line-length=120 lib/ test/
```
