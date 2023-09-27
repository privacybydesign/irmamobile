#!/usr/bin/env bash

flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run flutter_launcher_icons:main
dart format --line-length=120 lib/ test/ integration_test/
