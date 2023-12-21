#!/usr/bin/env bash

# Fix xcodebuild (15.0.1) symlink tmpdir issue (https://developer.apple.com/forums/thread/738091)
TMPDIR=$(cd -P "$TMPDIR" && pwd)

gomobile bind -target android -androidapi 23 -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge
gomobile bind -target ios -iosversion 12.0 -o ios/Runner/Irmagobridge.xcframework github.com/privacybydesign/irmamobile/irmagobridge
