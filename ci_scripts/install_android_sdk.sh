#!/usr/bin/env bash
# Downloads and installs all Android SDKs and SDK build tools needed for irmamobile.
# The environment variables ANDROID_HOME needs to be set and
# "$ANDROID_HOME/cmdline-tools/bin" needs to be added to the PATH.
set -euxo pipefail

# The command line tools are pinned between two bounds, so read both before
# bumping this:
#
#  * New enough to see the platforms below. The 2021 build we used to pin lists
#    nothing past platforms;android-36, so installing android-37 found no
#    package at all.
#  * Old enough to write SDK XML version 3. Revision 17.0 and up write version
#    4, which the Android Gradle Plugin cannot read ("This version only
#    understands SDK XML versions up to 3"); it then cannot see the platform it
#    just installed and fails with "Failed to find target with hash string
#    'android-37'".
#
# Revision 16.0 is the newest that satisfies both.
ANDROID_SDK_TOOLS_ZIP="commandlinetools-linux-12266719_latest.zip"
ANDROID_SDK_CHECKSUM="3fab261d5219d582321db0c5670b3bbafd563096bce3f6277eb358807fc15f6e"
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
# Everything the build needs should be listed here, not just the versions we
# name ourselves, so that the Android Gradle Plugin never has to install a
# component mid-build. build-tools 35.0.0 is AGP 8.13's own default, which is
# why it is here next to the 36.1.0 we ask for. cmdline-tools is pinned to a
# revision rather than `latest` for the SDK XML reason above; nothing reads the
# installed copy either way, since the PATH points at the unzipped
# cmdline-tools/bin.
sdkmanager --sdk_root="$ANDROID_HOME" \
  "cmdline-tools;16.0" \
  "ndk;$ANDROID_NDK_VERSION" \
  "cmake;3.22.1" \
  "platforms;android-35" \
  "platforms;android-36" \
  "platforms;android-37.0" \
  "build-tools;35.0.0" \
  "build-tools;36.1.0"

# Ensure that right NDK version is selected.
ln -s "$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION" "$ANDROID_HOME/ndk-bundle"
