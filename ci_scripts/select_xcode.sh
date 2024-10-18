#!/usr/bin/env bash
set -euxo pipefail

XCODE_VERSION="15.4"

# Location is based on the Xcode versions bundled with the macOS runners in GitHub Actions.
# https://github.com/actions/runner-images/blob/main/images/macos/macos-13-Readme.md#xcode
sudo xcode-select -s /Applications/Xcode_${XCODE_VERSION}.app/Contents/Developer
