#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# generate_sbom.sh — Generate a CycloneDX SBOM for the App Store/Play Store app.
#
# Usage:
#   ./generate_sbom.sh                      # writes build/sbom/yivi-app.cdx.json
#   ./generate_sbom.sh path/to/sbom.json    # writes to the given file
#
# The SBOM covers everything that ends up in yivi_app:
#   - Dart/Flutter packages   (yivi_app/pubspec.lock, which includes yivi_core)
#   - Go modules              (yivi_core/go.mod, compiled into irmagobridge)
#   - CocoaPods               (yivi_app/ios/Podfile.lock)
#   - Android libraries       (release runtime classpath of yivi_app/android)
#
# It also declares the prebuilt SQLCipher and OpenSSL libraries that bind_go.sh links into the
# Android Go bridge. Build tooling (fastlane's Gemfile) and dev/test-only dependencies are left out.
# The F-Droid flavor (yivi_fdroid) is a separate product and is not included.
#
# Merging is done by generate_sbom.mjs. Requires flutter, go, java (21+), node and npx on the
# PATH, and network access to look up licences.
# =============================================================================

CDXGEN_VERSION="12.8.5"
CDX_SPEC_VERSION="1.6"
# Both Play Store flavors have the same dependencies; beta is the one we publish.
ANDROID_CONFIGURATION="betaReleaseRuntimeClasspath"
# The OpenSSL version is the one the yivi-sqlcipher-prebuilt release used by bind_go.sh was built
# with; update it together with SQLCIPHER_VERSION there.
OPENSSL_VERSION="3.6.1"

root="$(cd "$(dirname "$0")" && pwd)"
out="${1:-$root/build/sbom/yivi-app.cdx.json}"
mkdir -p "$(dirname "$out")"
out="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

app_version="$(sed -n -E 's/^version: ([^+]+).*/\1/p' "$root/yivi_app/pubspec.yaml")"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export FETCH_LICENSE=true
cdxgen() {
  npx --yes "@cyclonedx/cdxgen@$CDXGEN_VERSION" --spec-version "$CDX_SPEC_VERSION" --no-auto-compositions --fail-on-error "$@"
}

# The Gradle wrapper is gitignored and only a Flutter Android build creates it. --config-only does
# that (and runs pub get) without compiling. The Gradle scan and the Podfile.lock plugin paths need both.
(cd "$root/yivi_app" && flutter build apk --config-only --flavor beta)

echo "Scanning Dart packages..."
cdxgen --type dart -o "$tmp/dart.cdx.json" "$root/yivi_app"

echo "Scanning Go modules..."
# Without the tag cdxgen misses the es256k modules that bind_go.sh links in.
GOFLAGS="-tags=jwx_es256k" cdxgen --type go -o "$tmp/go.cdx.json" "$root/yivi_core"
# cdxgen marks indirect modules as optional, even though they are compiled into the bridge.
# Ask Go which modules irmagobridge really links (with the build tags from bind_go.sh).
(cd "$root/yivi_core" && go list -deps -tags jwx_es256k \
  -f '{{with .Module}}{{if not .Main}}{{.Path}}@{{.Version}}{{end}}{{end}}' ./irmagobridge) \
  | sort -u | grep . > "$tmp/go-linked.txt"

echo "Scanning CocoaPods..."
# Darwin plugins declare a dependency on FlutterMacOS, which CocoaPods never installs for iOS.
# cdxgen crashes on that dangling reference, so we scan a copy of the lock file without it.
# The full scan runs `pod` per dependency and fails for our Podfile; generate_sbom.mjs adds the
# pod licences instead.
mkdir -p "$tmp/ios"
cp "$root/yivi_app/ios/Podfile" "$tmp/ios/"
grep -v -E '^    - FlutterMacOS$' "$root/yivi_app/ios/Podfile.lock" > "$tmp/ios/Podfile.lock"
COCOA_FULL_SCAN=false cdxgen --type cocoapods -o "$tmp/cocoapods.cdx.json" "$tmp/ios"

echo "Scanning Android libraries..."
# Only resolve the release runtime classpath of :app. That classpath already contains every
# Flutter plugin module, so the other Gradle projects, the root project and the included builds
# (Flutter's own Gradle plugin) are skipped.
android_modules="$(cd "$root/yivi_app/android" && ./gradlew -q projects | sed -n -E "s/.*(Project|Included build) '(:[^']+)'.*/\2/p" | grep -v -x ':app' | paste -s -d ',' -)"
GRADLE_SKIP_MODULES="root${android_modules:+,$android_modules}" \
GRADLE_ARGS_DEPENDENCIES="--configuration $ANDROID_CONFIGURATION" \
  cdxgen --type gradle -o "$tmp/gradle.cdx.json" "$root/yivi_app/android"

echo "Merging..."
# Used to leave out the Dart packages (and their plugin pods) that only dev dependencies pull in.
(cd "$root/yivi_app" && flutter pub deps --json) > "$tmp/pub-deps.json"
node "$root/generate_sbom.mjs" \
  --out "$out" \
  --version "$app_version" \
  --go-linked "$tmp/go-linked.txt" \
  --pub-deps "$tmp/pub-deps.json" \
  --pubspec-lock "$root/yivi_app/pubspec.lock" \
  --podfile-lock "$root/yivi_app/ios/Podfile.lock" \
  --sqlcipher-version "$(sed -n -E 's/^SQLCIPHER_VERSION="(.*)"/\1/p' "$root/bind_go.sh")" \
  --sqlcipher-sha256 "$(sed -n -E 's/^ANDROID_SHA256="(.*)"/\1/p' "$root/bind_go.sh")" \
  --openssl-version "$OPENSSL_VERSION" \
  "$tmp"/{dart,go,cocoapods,gradle}.cdx.json
