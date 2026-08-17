#!/usr/bin/env bash
# Downloads and installs all Android SDKs and SDK build tools needed for irmamobile.
# The environment variables ANDROID_HOME needs to be set and
# "$ANDROID_HOME/cmdline-tools/bin" needs to be added to the PATH.
set -euxo pipefail

# Keep the command line tools recent enough to see the platforms below. The
# 2021 build this used to pin lists nothing past platforms;android-36, so
# installing android-37 silently found no package.
ANDROID_SDK_TOOLS_ZIP="commandlinetools-linux-15859902_latest.zip"
ANDROID_SDK_CHECKSUM="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"
ANDROID_NDK_VERSION="28.2.13676358"

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
wget -q -O sdk.zip "https://dl.google.com/android/repository/${ANDROID_SDK_TOOLS_ZIP}"
shasum -a 256 -c - <<< "${ANDROID_SDK_CHECKSUM}  sdk.zip"

unzip -q sdk.zip -d "$ANDROID_HOME"
rm sdk.zip
popd

# Accept Android licenses
set +o pipefail
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses > /dev/null
set -o pipefail

# We pre-install some Android SDKs to prevent that Flutter downloads them on every app build.
# Which versions we need is dependent on our target Android SDK and the target Android SDK of our dependencies.
# There is no convenient way to determine this in Flutter yet. Therefore, we hardcode some versions here.
# Issue: https://github.com/flutter/flutter/issues/63533
#
# Everything the build needs must be listed here, not just the versions we name
# ourselves: if the Android Gradle Plugin installs any component itself during a
# build, the SDK it already loaded goes stale and resolving compileSdk 37 fails
# with "Failed to find target with hash string 'android-37'" in that same run.
# build-tools 35.0.0 is AGP 8.13's own default, which is why it is here next to
# the 36.1.0 we ask for.
sdkmanager --sdk_root="$ANDROID_HOME" \
  "cmdline-tools;latest" \
  "ndk;$ANDROID_NDK_VERSION" \
  "cmake;3.22.1" \
  "platforms;android-35" \
  "platforms;android-36" \
  "platforms;android-37.0" \
  "build-tools;35.0.0" \
  "build-tools;36.1.0"

# Ensure that right NDK version is selected.
ln -s "$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION" "$ANDROID_HOME/ndk-bundle"
