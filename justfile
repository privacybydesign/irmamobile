
# Generates the dart code for (de)serializing json
gen:
    cd yivi_core && dart run build_runner build --delete-conflicting-outputs

# Generates the bindings for irmaclient
bind:
    ./bind_go.sh

# Builds the App Store/PlayStore version of the app
build *args:
    cd yivi_app && flutter build {{args}}

# Builds the F-Droid version of the app
build-fdroid *args:
    cd yivi_fdroid && flutter build {{args}}

# Runs the App Store/PlayStore version of the app
run *args:
    cd yivi_app && flutter run {{args}}

# Runs the F-Droid version of the app
run-fdroid *args:
    cd yivi_fdroid && flutter run {{args}}

# Runs the unit tests
unit-test:
    cd yivi_core && flutter test

test:
    #!/usr/bin/env bash
    cd yivi_app
    file=$(find ./integration_test -name "**_test.dart" | fzf)
    echo "Running test: $file"
    flutter test "$file"

# Runs all the integration tests (and stores the logs in test.log)
test-all *args:
    cd yivi_app && flutter test integration_test/test_all.dart {{args}} | tee test.log

# Formats all Dart & Go code
fmt:
    dart format .
    cd yivi_core && go fmt ./...

# Checks the formatting for all the Flutter code
check-fmt:
    dart format --set-exit-if-changed --output none ./yivi_app ./yivi_core ./yivi_fdroid

# Analyzes all the Flutter code
lint: check-fmt
    cd yivi_core && flutter analyze --no-fatal-infos
    cd yivi_app && flutter analyze --no-fatal-infos
    cd yivi_fdroid && flutter analyze --no-fatal-infos

# Fetches or updates all Go and Flutter dependencies
get:
    cd yivi_core && go mod tidy
    cd yivi_core && flutter pub get
    cd yivi_app && flutter pub get
    cd yivi_fdroid && flutter pub get

# Applies all Flutter fixes that can be applied automatically
fix:
    cd yivi_core && dart fix --apply
    cd yivi_app && dart fix --apply
    cd yivi_fdroid && dart fix --apply

# Fetches or updates all Go and Flutter dependencies and generates go bindings
setup: get bind

