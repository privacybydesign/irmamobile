#!/usr/bin/env bash

gomobile bind -target android -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge
gomobile bind -target ios -iosversion 12.0 -o ios/Runner/Irmagobridge.xcframework github.com/privacybydesign/irmamobile/irmagobridge
