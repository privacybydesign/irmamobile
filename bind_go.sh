#!/usr/bin/env bash

cd yivi_core

gomobile bind -target android -androidapi 26 -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge
gomobile bind -target ios -iosversion 15.6 -o ios/Irmagobridge.xcframework github.com/privacybydesign/irmamobile/irmagobridge

# On Windows, create a directory junction for irma_configuration on Android, on Linux-style systems a symlink.
if [ ! -e "./android/src/main/assets/irma_configuration" ]; then
    if [[ "$OSTYPE" == "msys"* ]]; then
        cmd.exe <<<$"mklink /j .\android\src\main\assets\irma_configuration .\..\irma_configuration"
    else
        ln -s "../../../../../irma_configuration" "./android/src/main/assets/irma_configuration"
    fi
fi
