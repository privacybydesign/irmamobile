#!/usr/bin/env bash

gomobile bind -target android -androidapi 23 -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge
gomobile bind -target ios -iosversion 12.0 -o ios/Runner/Irmagobridge.xcframework github.com/privacybydesign/irmamobile/irmagobridge

# On Windows, create a directory junction for irma_configuration on Android, on Linux-style systems a symlink.
if [ ! -e "./android/app/src/main/assets/irma_configuration" ]; then
    if [[ "$OSTYPE" == "msys"* ]]; then
        cmd.exe <<<$"mklink /j .\android\app\src\main\assets\irma_configuration .\irma_configuration"
    else
        ln -s "../../../../../irma_configuration" "./android/app/src/main/assets/irma_configuration"
    fi
fi
