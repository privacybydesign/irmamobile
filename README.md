irmamobile
==========

### Authentication made easy, privacy-friendly, and secure

IRMA offers a privacy-friendly, flexible and secure solution to many authentication problems, putting the user in full control over his/her data.

The IRMA app manages the user's IRMA attributes: receiving new attributes, selectively disclosing them to others, and attaching them to signed statements. These attributes can be relevant properties, such as: "I am over 18", "my name is ..." and "I am entitled to access ....". They are only stored on the user's device and nowhere else.

## Building the app for development

* Only Android is supported for now
* Follow many of the steps for [irma_mobile](https://github.com/privacybydesign/irma_mobile/blob/master/README.md), excluding React Native stuff, but including setting up the Android SDK and installing the Android NDK through the SDK manager, setting up a Go environment and moving the project to `$GOPATH/src/github.com/privacybydesign/irmamobile`.
* For Android, run `gomobile bind -target android -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge`
* Start an emulator or connect a device, and run `flutter run`