#!/usr/bin/env bash
# Downloads and installs Flutter.
# The environment variables FLUTTER_HOME needs to be set and "$FLUTTER_HOME/bin" needs to be added to the PATH.
set -euxo pipefail

FLUTTER_VERSION="2.10.5"
FLUTTER_CHANNEL="stable"
FLUTTER_CHECKSUM_LINUX="0d3670c65314624f0d4b549a5942689578c3f899d15bbdcfb3909d4470c69edd"
FLUTTER_CHECKSUM_MACOS="cc3b48d864c5863898246b8f8e602489cc8e2e77098db27ef3484a25162e1c80"

if [[ -z "$FLUTTER_HOME" ]]; then
  echo "Environment variable FLUTTER_HOME needs to be set"
  exit 1
fi
if [[ ! "$PATH" =~ "$FLUTTER_HOME/bin" ]]; then
  echo "$FLUTTER_HOME/bin is not added to PATH"
  exit 1
fi

if [ -x "$(command -v "flutter")" ]; then
  exit 0
fi

mkdir -p "$FLUTTER_HOME"
pushd "$FLUTTER_HOME"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  wget -q -O ./flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz
  echo "${FLUTTER_CHECKSUM_LINUX}  flutter.tar.xz" | sha256sum -c
  tar xf flutter.tar.xz
elif [[ "$OSTYPE" == "darwin"* ]]; then
  wget -q -O ./flutter.zip https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/macos/flutter_macos_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip
  echo "${FLUTTER_CHECKSUM_MACOS}  flutter.zip" | sha256sum -c
  unzip -q flutter.zip
else
  echo "Unsupported operating system $OSTYPE"
  exit 1
fi
mv ./flutter/* .
rm -rf ./flutter/ ./flutter.zip ./flutter.tar.xz
popd

flutter config --no-analytics
flutter doctor -v
flutter precache
