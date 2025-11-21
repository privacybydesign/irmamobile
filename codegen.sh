#!/usr/bin/env bash

pushd yivi_core
dart run build_runner build --delete-conflicting-outputs
dart format lib/ test/
popd

pushd yivi_app
# dart run build_runner build --delete-conflicting-outputs
dart format lib/ integration_test/
popd

pushd yivi_fdroid
# dart run build_runner build --delete-conflicting-outputs
dart format lib/
popd
