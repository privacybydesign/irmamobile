#!/usr/bin/env bash
# Downloads and installs all Android SDKs and SDK build tools needed for irmamobile.
# The environment variables ANDROID_HOME needs to be set and
# "$ANDROID_HOME/cmdline-tools/bin" needs to be added to the PATH.
set -euxo pipefail

ANDROID_SDK_CHECKSUM="124f2d5115eee365df6cf3228ffbca6fc3911d16f8025bebd5b1c6e2fcfa7faf"
ANDROID_NDK_VERSION="21.4.7075529"

if [[ -z "$ANDROID_HOME" ]]; then
  echo "Environment variable ANDROID_HOME needs to be set"
  exit 1
fi
if [[ ! "$PATH" =~ "$ANDROID_HOME/cmdline-tools/bin" ]]; then
  echo "$ANDROID_HOME/cmdline-tools/bin is not added to PATH"
  exit 1
fi
if [[ "$ANDROID_NDK_HOME" != "$ANDROID_HOME/ndk-bundle" ]]; then
  echo "Environment variable ANDROID_NDK_HOME needs to be set to \$ANDROID_HOME/ndk-bundle"
  exit 1
fi

# We assume that Java is already installed.
if [ ! -x "$(command -v "java")" ]; then
  echo "Java not installed"
  exit 1
fi

if [ -x "$(command -v "sdkmanager")" ]; then
  exit 0
fi

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo "Unsupported operating system $OSTYPE"
  exit 1
fi

mkdir -p "$ANDROID_HOME"
pushd "$ANDROID_HOME"
wget -q -O sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip
shasum -a 256 -c - <<< "${ANDROID_SDK_CHECKSUM}  sdk.zip"

unzip -q sdk.zip -d "$ANDROID_HOME"
rm sdk.zip
popd

# Accept Android licenses
set +o pipefail
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses > /dev/null
set -o pipefail

# Flutter 2 needs Android SDK platform 28 to 32 and build-tools 30 and 32. We pre-install them
# to prevent that Flutter downloads them on every app build.
sdkmanager --sdk_root="$ANDROID_HOME" \
  "platform-tools" \
  "ndk;$ANDROID_NDK_VERSION" \
  "cmake;3.10.2.4988404" \
  "platforms;android-28" \
  "platforms;android-29" \
  "platforms;android-30" \
  "platforms;android-31" \
  "platforms;android-32" \
  "build-tools;30.0.2" \
  "build-tools;32.0.0"

# Ensure that right NDK version is selected.
ln -s "$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION" "$ANDROID_HOME/ndk-bundle"
