#!/usr/bin/env bash

export GO111MODULE=off
gomobile bind -target android -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge
