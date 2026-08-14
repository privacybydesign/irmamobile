#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install_flutter_test.sh — Test install_flutter.sh without downloading an SDK.
#
# The macOS half of install_flutter.sh only ever runs on a macOS CI runner, and
# the two macOS archives differ by one infix in the URL, so picking the wrong
# one is invisible: the install succeeds and everything afterwards just runs
# under Rosetta. This runs the script against a stub wget/shasum/unzip/tar/uname
# and asserts the archive URL and the checksum handed to shasum belong to the
# same platform.
#
# It lives in ci_scripts/tests/ rather than next to the script because the
# setup-build-environment action keys its SDK cache on hashFiles('ci_scripts/*'),
# which does not descend into subdirectories. A test file directly in ci_scripts/
# would throw away the cached Flutter and Android SDKs on every edit to it.
#
# Usage: ./ci_scripts/tests/install_flutter_test.sh
# =============================================================================

SCRIPT_UNDER_TEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/install_flutter.sh"

FAILURES=0

fail() {
  echo "  FAIL: $*" >&2
  FAILURES=$((FAILURES + 1))
}

assert_contains() {
  local file="$1" needle="$2" what="$3"
  if ! grep -qF -- "$needle" "$file"; then
    fail "$what: expected to find: $needle"
    echo "  --- recorded calls ---" >&2
    sed 's/^/  /' "$file" >&2
  fi
}

assert_not_contains() {
  local file="$1" needle="$2" what="$3"
  if grep -qF -- "$needle" "$file"; then
    fail "$what: expected NOT to find: $needle"
    echo "  --- recorded calls ---" >&2
    sed 's/^/  /' "$file" >&2
  fi
}

# Read the pin and the checksums out of the script itself, so bumping the
# version does not touch this test and so a checksum swapped between the two
# macOS architectures still fails.
read_var() {
  sed -n "s/^$1=\"\\(.*\\)\"\$/\\1/p" "$SCRIPT_UNDER_TEST"
}

VERSION="$(read_var FLUTTER_VERSION)"
CHANNEL="$(read_var FLUTTER_CHANNEL)"
SUM_LINUX="$(read_var FLUTTER_CHECKSUM_LINUX)"
SUM_MACOS_X64="$(read_var FLUTTER_CHECKSUM_MACOS_X64)"
SUM_MACOS_ARM64="$(read_var FLUTTER_CHECKSUM_MACOS_ARM64)"

for name in VERSION CHANNEL SUM_LINUX SUM_MACOS_X64 SUM_MACOS_ARM64; do
  if [ -z "${!name}" ]; then
    echo "FAIL: could not read $name from $SCRIPT_UNDER_TEST" >&2
    exit 1
  fi
done

if [ "$SUM_MACOS_X64" = "$SUM_MACOS_ARM64" ]; then
  fail "the two macOS checksums are identical, so they cannot both be right"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# -----------------------------------------------------------------------------
# Run install_flutter.sh once, with $OSTYPE, `uname -m` and `sysctl` faked, and
# return the log of how the stub tooling was called.
#
#   run_install <ostype> <machine> <hw.optional.arm64> <calls-file>
#
# Pass "" for <hw.optional.arm64> to make sysctl exit non-zero the way it does
# when the key does not exist. An Intel Mac gives either that or a plain 0.
# -----------------------------------------------------------------------------
run_install() {
  local ostype="$1" machine="$2" hw_arm64="$3" calls="$4"
  local case_dir stub_bin flutter_home
  case_dir="$WORK/$ostype-$machine-${hw_arm64:-none}"
  stub_bin="$case_dir/stub-bin"
  flutter_home="$case_dir/flutter-home"
  mkdir -p "$stub_bin" "$flutter_home"
  : > "$calls"

  cat > "$stub_bin/uname" <<EOF
#!/bin/sh
[ "\$1" = "-m" ] && echo "$machine" || echo "$ostype"
EOF

  cat > "$stub_bin/sysctl" <<EOF
#!/bin/sh
[ -n "$hw_arm64" ] || exit 1
echo "$hw_arm64"
EOF

  # Records the URL and leaves an archive behind for the extraction stubs.
  cat > "$stub_bin/wget" <<EOF
#!/bin/sh
out=""
url=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    -O) out="\$2"; shift 2 ;;
    -*) shift ;;
    *) url="\$1"; shift ;;
  esac
done
echo "wget \$url" >> "$calls"
echo "archive" > "\$out"
EOF

  # The real one reads "<checksum>  <file>" on stdin; record the checksum.
  cat > "$stub_bin/shasum" <<EOF
#!/bin/sh
read -r checksum file
echo "shasum \$checksum \$file" >> "$calls"
EOF

  # Both extraction stubs lay down what the archives contain: a ./flutter with
  # the SDK in it, which the script then moves into FLUTTER_HOME.
  cat > "$stub_bin/extract" <<EOF
#!/bin/sh
echo "extract \$*" >> "$calls"
mkdir -p ./flutter/bin
touch ./flutter/.dotfile
cat > ./flutter/bin/flutter <<'INNER'
#!/bin/sh
echo "flutter \$*" >> "$calls"
INNER
chmod +x ./flutter/bin/flutter
EOF
  cp "$stub_bin/extract" "$stub_bin/unzip"
  cp "$stub_bin/extract" "$stub_bin/tar"
  rm "$stub_bin/extract"

  chmod +x "$stub_bin"/*

  # A fixed PATH, so a Flutter installed on the machine running this test does
  # not make the script skip the download it is here to check.
  env -i \
    HOME="$case_dir" \
    OSTYPE="$ostype" \
    FLUTTER_HOME="$flutter_home" \
    PATH="$stub_bin:$flutter_home/bin:/usr/bin:/bin" \
    bash "$SCRIPT_UNDER_TEST" > "$case_dir/out" 2>&1
}

BASE="https://storage.googleapis.com/flutter_infra_release/releases/$CHANNEL"

# -----------------------------------------------------------------------------
echo "macOS on Apple Silicon takes the arm64 archive"
# -----------------------------------------------------------------------------
CALLS="$WORK/arm64.log"
run_install darwin24 arm64 1 "$CALLS"
assert_contains "$CALLS" \
  "wget $BASE/macos/flutter_macos_arm64_$VERSION-$CHANNEL.zip" "arm64"
assert_contains "$CALLS" "shasum $SUM_MACOS_ARM64 flutter.zip" "arm64"
assert_contains "$CALLS" "flutter precache" "arm64"

# -----------------------------------------------------------------------------
echo "macOS from a Rosetta shell still takes the arm64 archive"
# -----------------------------------------------------------------------------
# Under Rosetta `uname -m` says x86_64 on Apple Silicon hardware; only sysctl
# tells the truth.
CALLS="$WORK/rosetta.log"
run_install darwin24 x86_64 1 "$CALLS"
assert_contains "$CALLS" \
  "wget $BASE/macos/flutter_macos_arm64_$VERSION-$CHANNEL.zip" "rosetta"
assert_contains "$CALLS" "shasum $SUM_MACOS_ARM64 flutter.zip" "rosetta"

# -----------------------------------------------------------------------------
echo "macOS on Intel takes the x64 archive"
# -----------------------------------------------------------------------------
# Both ways an Intel Mac can answer: sysctl exits non-zero because the key does
# not exist, or it prints 0.
for hw_arm64 in "" 0; do
  CALLS="$WORK/x64-${hw_arm64:-none}.log"
  run_install darwin24 x86_64 "$hw_arm64" "$CALLS"
  assert_contains "$CALLS" \
    "wget $BASE/macos/flutter_macos_$VERSION-$CHANNEL.zip" "x64"
  assert_not_contains "$CALLS" "flutter_macos_arm64_" "x64"
  assert_contains "$CALLS" "shasum $SUM_MACOS_X64 flutter.zip" "x64"
done

# -----------------------------------------------------------------------------
echo "Linux is unaffected by the macOS architecture split"
# -----------------------------------------------------------------------------
CALLS="$WORK/linux.log"
run_install linux-gnu x86_64 "" "$CALLS"
assert_contains "$CALLS" \
  "wget $BASE/linux/flutter_linux_$VERSION-$CHANNEL.tar.xz" "linux"
assert_contains "$CALLS" "shasum $SUM_LINUX flutter.tar.xz" "linux"

# -----------------------------------------------------------------------------
echo "the pinned checksums are the ones Flutter published"
# -----------------------------------------------------------------------------
# Every check above reads the checksums out of the script, so together they
# prove each branch reaches for the right variable, but not that the variable
# holds the right hash. Swapping the two macOS values passes all of them, and
# that is exactly the slip the architecture split invites: the checksums sit on
# adjacent lines and neither one carries its architecture anywhere a reader can
# check it against. Only a source outside the script settles it, so read the
# release manifest.
#
# A macOS-only failure is what a wrong value costs: shasum rejects the archive
# on the runner and the job dies at setup with no hint at which of the two
# lines is wrong.
MANIFEST_SKIPS=0

# Print the sha256 the manifest lists for one archive. Returns non-zero only
# when the manifest cannot be fetched; an archive that is absent from it prints
# nothing and succeeds, which the caller reports separately.
manifest_sha256() {
  local platform="$1" archive="$2" manifest="$WORK/releases_$platform.json"
  if [ ! -s "$manifest" ]; then
    curl -sSf --max-time 60 -o "$manifest" \
      "https://storage.googleapis.com/flutter_infra_release/releases/releases_$platform.json" \
      2>/dev/null || return 1
  fi
  # The manifest is pretty-printed one field per line, and "sha256" is the
  # field right after the "archive" it belongs to.
  awk -v want="\"$CHANNEL/$platform/$archive\"," '
    $1 == "\"archive\":"           { found = ($2 == want) }
    found && $1 == "\"sha256\":"   { gsub(/[",]/, "", $2); print $2; exit }
  ' "$manifest"
}

assert_published_checksum() {
  local platform="$1" archive="$2" expected="$3" what="$4"
  local actual
  if ! actual="$(manifest_sha256 "$platform" "$archive")"; then
    echo "  SKIP: could not fetch the $platform release manifest" >&2
    MANIFEST_SKIPS=$((MANIFEST_SKIPS + 1))
    return
  fi
  if [ -z "$actual" ]; then
    fail "$what: $archive is not in the $platform release manifest"
  elif [ "$actual" != "$expected" ]; then
    fail "$what: the script pins $expected, the manifest publishes $actual"
  fi
}

assert_published_checksum macos "flutter_macos_$VERSION-$CHANNEL.zip" \
  "$SUM_MACOS_X64" "macOS x64"
assert_published_checksum macos "flutter_macos_arm64_$VERSION-$CHANNEL.zip" \
  "$SUM_MACOS_ARM64" "macOS arm64"
assert_published_checksum linux "flutter_linux_$VERSION-$CHANNEL.tar.xz" \
  "$SUM_LINUX" "Linux"

# -----------------------------------------------------------------------------
if [ "$FAILURES" -ne 0 ]; then
  echo "$FAILURES check(s) failed" >&2
  exit 1
fi
if [ "$MANIFEST_SKIPS" -ne 0 ]; then
  # Not a failure: a network blip should not break the lint gate. It does mean
  # the checksum values went unchecked on this run, so say so rather than
  # letting "All checks passed" imply more than it covered.
  echo "All checks passed ($MANIFEST_SKIPS checksum(s) unverified, manifest unreachable)"
  exit 0
fi
echo "All checks passed"
