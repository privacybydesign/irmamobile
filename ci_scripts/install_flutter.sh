#!/usr/bin/env bash
# Downloads and installs Flutter.
# The environment variables FLUTTER_HOME needs to be set and "$FLUTTER_HOME/bin" needs to be added to the PATH.
set -euxo pipefail

FLUTTER_VERSION="3.32.6"
FLUTTER_CHANNEL="stable"

# these checksums are made by downloading the SDK from https://docs.flutter.dev/release/archive and running
# `shasum -a 256 <file>` over them
FLUTTER_CHECKSUM_LINUX="1c838fe8dd5bf93722bf42bf5da59425bf809cbfed17fea8385771e78ccf442b"
FLUTTER_CHECKSUM_MACOS="34df2364c8d15e0d5046ec2c0ed7796e709ba2f39e8d3364157da74cdf99d74b"

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
flutter doctor -v
flutter precache
