#!/usr/bin/env bash
# Downloads and installs Flutter.
# The environment variables FLUTTER_HOME needs to be set and "$FLUTTER_HOME/bin" needs to be added to the PATH.
set -euxo pipefail

FLUTTER_VERSION="3.47.0"
FLUTTER_CHANNEL="stable"

# these checksums are made by downloading the SDK from https://docs.flutter.dev/release/archive and running
# `shasum -a 256 <file>` over them
FLUTTER_CHECKSUM_LINUX="26cd99d3d94b1367e6b50535a18aeef0282c10a535bbe3ec493534dcdab75296"
FLUTTER_CHECKSUM_MACOS="74af3192ae4bcbceb6d35f8ed332af16b7ff00af300520b02fbea456ae3e955d"

if [[ -z "$FLUTTER_HOME" ]]; then
  echo "Environment variable FLUTTER_HOME needs to be set"
  exit 1
fi
if [[ ! "$PATH" =~ "$FLUTTER_HOME/bin" ]]; then
  echo "$FLUTTER_HOME/bin is not added to PATH"
  exit 1
fi

if ! [ -x "$(command -v "flutter")" ]; then
  mkdir -p "$FLUTTER_HOME"
  pushd "$FLUTTER_HOME"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    wget -q -O ./flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz
    shasum -a 256 -c - <<< "${FLUTTER_CHECKSUM_LINUX}  flutter.tar.xz"
    tar xf flutter.tar.xz
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    wget -q -O ./flutter.zip https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/macos/flutter_macos_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip
    shasum -a 256 -c - <<< "${FLUTTER_CHECKSUM_MACOS}  flutter.zip"
    unzip -q flutter.zip
  else
    echo "Unsupported operating system $OSTYPE"
    exit 1
  fi
  # Move all files and directories (including the hidden ones) to the root directory of FLUTTER_HOME.
  (shopt -s dotglob && mv ./flutter/* .)
  rm -rf ./flutter/ ./flutter.zip ./flutter.tar.xz
  popd
fi

flutter config --no-analytics
# `flutter doctor -v` is purely diagnostic and on macOS spends ~2 minutes
# enumerating every installed iOS Simulator runtime (the "Connected device"
# check). Build failures already surface tool problems loudly enough; skip it.
flutter precache
