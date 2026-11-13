#!/usr/bin/env bash
# Guards security settings that are easy to undo by accident and that no test
# notices: a manifest attribute, a build flag, a forbidden API. Each check names
# the requirement of the OWASP MAS EUDI Wallet profile it belongs to.
#
# Usage: ./ci_scripts/check_security_config.sh   (from anywhere in the repository)
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

# Fails when a pattern occurs in the given paths. Comment-only lines are ignored,
# so that a comment may name the thing that is forbidden.
forbid() {
  local description="$1" pattern="$2"
  shift 2
  local hits
  hits="$(grep -rnE "$pattern" "$@" 2>/dev/null | grep -vE '^[^:]+:[0-9]+:\s*(//|#|\*|/\*|<!--)' || true)"
  if [ -n "$hits" ]; then
    fail "$description"
    echo "$hits" | sed 's/^/      /'
  fi
}

# Fails when a file lacks a fixed string.
require() {
  local description="$1" needle="$2" file="$3"
  if ! grep -qF -- "$needle" "$file"; then
    fail "$description ($file)"
  fi
}

DART_SOURCES=(yivi_core/lib yivi_app/lib yivi_fdroid/lib)
ANDROID_SOURCES=(yivi_core/android/src/main yivi_app/android/app/src yivi_fdroid/android/app/src)
ANDROID_APPS=(yivi_app yivi_fdroid)

# 2: no sensitive data outside the app's private storage.
forbid "Dart code writes to shared storage or shares files" \
  'getExternalStorageDirector|getDownloadsDirectory|shareXFiles' \
  --include='*.dart' "${DART_SOURCES[@]}"

# 6: app data is excluded from backups and device transfers.
# 26: no cleartext traffic, only the system's certificate authorities.
for app in "${ANDROID_APPS[@]}"; do
  manifest="$app/android/app/src/main/AndroidManifest.xml"
  require "allowBackup must stay off" 'android:allowBackup="false"' "$manifest"
  require "the data extraction rules must stay referenced" \
    'android:dataExtractionRules="@xml/data_extraction_rules"' "$manifest"
  require "the network security configuration must stay referenced" \
    'android:networkSecurityConfig="@xml/network_security_config"' "$manifest"
  require "cleartext traffic must stay off" 'cleartextTrafficPermitted="false"' \
    "$app/android/app/src/main/res/xml/network_security_config.xml"
done
forbid "an Android manifest allows cleartext traffic" \
  'usesCleartextTraffic="true"|cleartextTrafficPermitted="true"' \
  --include='*.xml' "${ANDROID_SOURCES[@]}"
forbid "the network security configuration trusts user-installed certificates" \
  'certificates src="user"' --include='*.xml' "${ANDROID_SOURCES[@]}"
forbid "App Transport Security is switched off on iOS" \
  'NSAllowsArbitraryLoads' yivi_app/ios/Runner/Info.plist

# 27: certificate validation is not weakened on any network stack.
forbid "certificate validation is weakened in Go" \
  'InsecureSkipVerify:[[:space:]]*true' --include='*.go' yivi_core/irmagobridge
forbid "certificate validation is weakened in Dart" \
  'badCertificateCallback' --include='*.dart' "${DART_SOURCES[@]}"
forbid "certificate validation is weakened on Android" \
  'X509TrustManager|HostnameVerifier|onReceivedSslError' \
  --include='*.java' --include='*.kt' "${ANDROID_SOURCES[@]}"

# 49: no code is loaded at run time.
forbid "Android code loads code at run time" \
  'DexClassLoader|PathClassLoader|InMemoryDexClassLoader|System\.load\(' \
  --include='*.java' --include='*.kt' "${ANDROID_SOURCES[@]}"

# 59: release builds are obfuscated.
require "the Android release build must obfuscate the Dart code" \
  'cmd += " --obfuscate --split-debug-info=' fastlane/Fastfile
require "the iOS release build must obfuscate the Dart code" \
  '"--obfuscate", "--split-debug-info=' fastlane/Fastfile
require "the Go bridge must be built without symbols and build paths" \
  'GO_BUILD_FLAGS=(-trimpath -ldflags "-s -w")' bind_go.sh
require "R8 must stay on for the Android release build" \
  'minifyEnabled true' yivi_app/android/app/build.gradle

# 63: debug mechanisms are off in release builds.
forbid "an Android manifest marks the app debuggable" \
  'android:debuggable="true"' --include='*.xml' "${ANDROID_SOURCES[@]}"
forbid "WebView debugging is switched on" \
  'setWebContentsDebuggingEnabled\(true\)|enableDebugging\(true\)' \
  --include='*.java' --include='*.kt' --include='*.dart' \
  "${ANDROID_SOURCES[@]}" "${DART_SOURCES[@]}"

if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures security configuration check(s) failed."
  exit 1
fi
echo "Security configuration checks passed."
