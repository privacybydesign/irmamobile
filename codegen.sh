#!/usr/bin/env bash

dart run build_runner build --delete-conflicting-outputs
dart run flutter_launcher_icons
dart format --line-length=120 lib/ test/ integration_test/
