#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# bind_go.sh — Build the Go bridge (irmagobridge) for Android and iOS.
#
# Usage:
#   ./bind_go.sh              # build all platforms (Android + iOS)
#   ./bind_go.sh android      # build Android only
#   ./bind_go.sh ios          # build iOS only
#   ./bind_go.sh android/arm64 # build a single Android ABI (fastest for dev)
#
# This script wraps `gomobile bind` to produce:
#   - yivi_core/android/irmagobridge/irmagobridge.aar  (Android)
#   - yivi_core/ios/Irmagobridge.xcframework            (iOS)
#
# The Go code in irmago links against SQLCipher (encrypted SQLite) via CGo.
# On iOS, CocoaPods provides SQLCipher at link time (see yivi_core.podspec).
# On Android, there is no package manager for native libs, so we download
# prebuilt static SQLCipher + OpenSSL libraries from
# https://github.com/privacybydesign/yivi-sqlcipher-prebuilt/releases
# and link them into libgojni.so ourselves.
#
# The same applies to the zero-knowledge prover, downloaded from
# https://github.com/privacybydesign/longfellow-go/releases
#
# Both sets are cached in build/sqlcipher-prebuilt/ and build/longfellow-prebuilt/
# and only downloaded once. Delete a directory to force a re-download.
#
# Each Android ABI needs its own -I/-L flags pointing to the matching static
# libs. Since gomobile doesn't support per-ABI CGO flags and the linker
# rejects .a files for the wrong architecture, we invoke gomobile once per
# ABI and merge the resulting libgojni.so files into a single AAR.
#
# Prerequisites:
#   - Go, gomobile (see ci_scripts/install_gomobile.sh)
#   - ANDROID_HOME set, NDK installed
#   - Xcode (for iOS)
#   - pkg-config + sqlcipher (brew install sqlcipher) for iOS host linking
# =============================================================================

# --- Parse arguments ---
# Determine which platforms/ABIs to build based on the first argument.
BUILD_TARGET="${1:-all}"

BUILD_ANDROID=false
BUILD_IOS=false
ANDROID_TARGETS="android/arm64 android/arm android/amd64"

case "$BUILD_TARGET" in
  all)
    BUILD_ANDROID=true
    BUILD_IOS=true
    ;;
  android)
    BUILD_ANDROID=true
    ;;
  ios)
    BUILD_IOS=true
    ;;
  android/arm64|android/arm|android/amd64)
    # Single ABI — fastest option for local development.
    BUILD_ANDROID=true
    ANDROID_TARGETS="$BUILD_TARGET"
    ;;
  *)
    echo "Usage: $0 [all|android|ios|android/arm64|android/arm|android/amd64]"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SQLCIPHER_VERSION="4.14.0"
PREBUILT_DIR="${SCRIPT_DIR}/build/sqlcipher-prebuilt"
SQLCIPHER_BASE_URL="https://github.com/privacybydesign/yivi-sqlcipher-prebuilt/releases/download/v${SQLCIPHER_VERSION}"
SQLCIPHER_ANDROID_SHA256="2ef9e2a78bdf6d9c92f49efd7b3676147242e2e4566c1d64f0335082b0ddf55e"

# The zero-knowledge prover's static libraries, per ABI, in the same layout and
# for the same reason as SQLCipher's: gomobile cannot pass per-ABI CGO flags, so
# each ABI is bound separately against its own .a files.
#
# Downloaded and pinned exactly as SQLCipher is, from a longfellow-go release
# built by its scripts/package-android-libs.sh. The version is the longfellow-zk
# commit plus the digest of the patch set applied over it, which is what the
# release tag encodes and what android/MANIFEST.txt inside the tarball records,
# so bumping the prover is the same two-line edit as bumping SQLCipher.
#
# It was once left to each developer to produce, which meant the ordinary build
# silently linked no prover and said so in one line: a wallet that works, and
# quietly falls back to the plain ISO mDoc presentation on every request. That
# fallback is still correct where there is genuinely no prover -- AV Annex A
# section A.8 requires it of any device that cannot generate a proof -- but it
# is the wrong default for a build that could have had one.
LONGFELLOW_DIR="${SCRIPT_DIR}/build/longfellow-prebuilt"
LONGFELLOW_VERSION="61a8a73-p57fad080"
LONGFELLOW_BASE_URL="https://github.com/privacybydesign/longfellow-go/releases/download/prebuilt-${LONGFELLOW_VERSION}"
LONGFELLOW_ANDROID_TARBALL="longfellow-${LONGFELLOW_VERSION}-android.tar.gz"
LONGFELLOW_ANDROID_SHA256="4a42c167c85d8a1adbd45d781676845172f5316606eb4396f0ba1fb7bfa02164"

# Set to 0 by a build that must not consume prebuilt binaries. F-Droid forbids
# them outright, and yivi_fdroid/fdroid_build.sh cross-compiles both sets from
# source into the directories above instead -- but only builds the prover when
# its source checkouts are supplied, and a download here would quietly put a
# prebuilt binary into the one build that may not have one.
#
# With downloads off, a set that is not already there is simply absent: for the
# prover that is the documented no-prover build, and for SQLCipher the gomobile
# link fails immediately afterwards naming what it could not find.
ALLOW_PREBUILT_DOWNLOADS="${ALLOW_PREBUILT_DOWNLOADS:-1}"

# Detect host OS for NDK toolchain prebuilt path selection.
detect_host_os() {
  local uname
  uname="$(uname -s)"
  case "$uname" in
    Darwin*)            echo "darwin-x86_64" ;;
    Linux*)             echo "linux-x86_64" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows-x86_64" ;;
    *)  echo "Unsupported host OS: $uname" >&2; exit 1 ;;
  esac
}

# Convert a Windows absolute path (e.g. C:\foo\bar) to a WSL mount path
# (e.g. /c/foo/bar). Only the leading drive letter is special-cased;
# remaining backslashes are replaced with forward slashes.
win_to_wsl_path() {
  local p="${1//\\//}"
  if [[ "$p" =~ ^([A-Za-z]):(.*) ]]; then
    p="/${BASH_REMATCH[1],,}${BASH_REMATCH[2]}"
  fi
  echo "$p"
}

HOST_OS="$(detect_host_os)"
# Under WSL, ANDROID_HOME is a Windows path; convert it to a WSL mount path.
if [ "$HOST_OS" = "windows-x86_64" ]; then
  ANDROID_HOME="$(win_to_wsl_path "$ANDROID_HOME")"
  ANDROID_HOME="${ANDROID_HOME%/}"
fi

# arm64-v8a cross-compilation is not supported on Windows; remove it.
if [ "$HOST_OS" = "windows-x86_64" ]; then
  if echo "$ANDROID_TARGETS" | grep -q 'android/arm64'; then
    echo "==> Skipping arm64-v8a (not supported on Windows)."
    ANDROID_TARGETS="${ANDROID_TARGETS//android\/arm64/}"
    ANDROID_TARGETS="${ANDROID_TARGETS//  / }"
    ANDROID_TARGETS="${ANDROID_TARGETS# }"
    ANDROID_TARGETS="${ANDROID_TARGETS% }"
  fi
fi

# --- ABI mapping helper ---

get_abi() {
  case "$1" in
    android/arm64) echo "arm64-v8a" ;;
    android/arm)   echo "armeabi-v7a" ;;
    android/amd64) echo "x86_64" ;;
  esac
}

# =============================================================================
# Download and verify the prebuilt static libraries: SQLCipher + OpenSSL, and
# the zero-knowledge prover.
# =============================================================================

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  if command -v sha256sum &>/dev/null; then
    actual="$(sha256sum "$file" | cut -d' ' -f1)"
  else
    actual="$(shasum -a 256 "$file" | cut -d' ' -f1)"
  fi
  if [ "$actual" != "$expected" ]; then
    echo "ERROR: SHA256 checksum mismatch for $(basename "$file")"
    echo "  Expected: ${expected}"
    echo "  Got:      ${actual}"
    rm -f "$file"
    exit 1
  fi
}

# Fetch <url> into <root>, check it against <sha256>, and unpack it there.
#
# <marker> is the directory the tarball unpacks to, and its presence is the
# cache: a second run downloads nothing, and neither does a tree that already
# has the libraries from somewhere else. yivi_fdroid/fdroid_build.sh depends on
# exactly that -- F-Droid forbids prebuilt binaries, so it cross-compiles both
# sets from source into these same directories and this function then finds its
# work already done.
download_prebuilt() {
  local label="$1"
  local root="$2"
  local marker="$3"
  local tarball="$4"
  local url="$5"
  local expected_sha256="$6"

  if [ -d "${root}/${marker}" ]; then
    echo "==> Prebuilt ${label} already available."
    return
  fi

  if [ "${ALLOW_PREBUILT_DOWNLOADS:-1}" != "1" ]; then
    echo "==> Prebuilt ${label} absent and downloads are disabled; continuing without it."
    return
  fi

  local tmpfile="${root}/${tarball}"

  mkdir -p "${root}"
  echo "==> Downloading prebuilt ${label}..."
  curl -fSL -o "$tmpfile" "$url"

  verify_sha256 "$tmpfile" "$expected_sha256"

  tar -xzf "$tmpfile" -C "${root}"
  rm -f "$tmpfile"
  echo "==> Prebuilt ${label} ready."
}

# =============================================================================
# Build the Go bridge with gomobile bind.
#
# All gomobile invocations (Android ABIs + iOS) run in parallel.
# After all builds complete, the per-ABI Android AARs are merged into one.
# =============================================================================

if [ "$BUILD_ANDROID" = true ]; then
  download_prebuilt "SQLCipher ${SQLCIPHER_VERSION} for android" \
    "${PREBUILT_DIR}" android \
    "sqlcipher-${SQLCIPHER_VERSION}-android.tar.gz" \
    "${SQLCIPHER_BASE_URL}/sqlcipher-${SQLCIPHER_VERSION}-android.tar.gz" \
    "${SQLCIPHER_ANDROID_SHA256}"

  download_prebuilt "longfellow ${LONGFELLOW_VERSION} for android" \
    "${LONGFELLOW_DIR}" android \
    "${LONGFELLOW_ANDROID_TARBALL}" \
    "${LONGFELLOW_BASE_URL}/${LONGFELLOW_ANDROID_TARBALL}" \
    "${LONGFELLOW_ANDROID_SHA256}"
fi

cd yivi_core

# --- Helper: build one Android ABI into an AAR ---
build_android_abi() {
  local target="$1"
  local outfile="$2"
  local abi
  abi="$(get_abi "$target")"
  local android_dir="${PREBUILT_DIR}/android"
  local longfellow_dir="${LONGFELLOW_DIR}/android"

  local cflags="-I${android_dir}/include -I${android_dir}/include/sqlcipher"
  local ldflags="-L${android_dir}/${abi}/lib"
  local tags="jwx_es256k"

  # Link the zero-knowledge prover only when its libraries exist for THIS abi.
  # The build tag is what decides whether irmagobridge imports longfellow-go at
  # all, so a tree without the libraries compiles with no reference to it and
  # links nothing extra -- see irmagobridge/zkprover_off.go.
  if [ -f "${longfellow_dir}/${abi}/lib/libmdoc_static.a" ]; then
    cflags="${cflags} -I${longfellow_dir}/include"
    ldflags="${ldflags} -L${longfellow_dir}/${abi}/lib"
    tags="${tags},longfellow"
    echo "    ${abi}: linking the zero-knowledge prover"
  else
    echo "    ${abi}: no longfellow libraries, building without the prover"
  fi

  echo "==> Building gomobile for ${target} (${abi})..."

  CGO_CFLAGS="${cflags}" \
  CGO_LDFLAGS="${ldflags}" \
  gomobile bind -target "${target}" -androidapi 26 \
    -o "${outfile}" \
    -tags "${tags}" \
    github.com/privacybydesign/irmamobile/irmagobridge
}

# Collect all background PIDs so we can wait for everything at the end.
ALL_PIDS=()

# --- iOS ---
# On iOS, SQLCipher is provided as a CocoaPods dependency (see yivi_core.podspec).
# The #cgo directive in sqlcipher.go uses pkg-config to find the host sqlcipher
# headers at compile time; CocoaPods links the actual library at app build time.
if [ "$BUILD_IOS" = true ]; then
  echo "==> Building gomobile for ios..."
  gomobile bind -target ios -iosversion 15.6 -o ios/Irmagobridge.xcframework \
    -tags jwx_es256k \
    github.com/privacybydesign/irmamobile/irmagobridge &
  ALL_PIDS+=($!)
fi

# --- Android ---
# We build each ABI separately because each needs -I/-L flags pointing to its
# own architecture-specific static SQLCipher + OpenSSL libraries. The linker
# rejects .a files for the wrong architecture, so we can't pass all paths at
# once. All ABIs run in parallel (alongside iOS).
ANDROID_TMPDIRS=()

if [ "$BUILD_ANDROID" = true ]; then
  read -ra TARGETS <<< "$ANDROID_TARGETS"

  if [ "${#TARGETS[@]}" -eq 1 ]; then
    # Single ABI — build directly into the final AAR, no merging needed.
    build_android_abi "${TARGETS[0]}" android/irmagobridge/irmagobridge.aar &
    ALL_PIDS+=($!)
  else
    # Multiple ABIs — build each into a temp AAR in parallel, merge after.
    for target in "${TARGETS[@]}"; do
      tmpdir="$(mktemp -d)"
      ANDROID_TMPDIRS+=("$tmpdir")
      build_android_abi "$target" "${tmpdir}/irmagobridge.aar" &
      ALL_PIDS+=($!)
    done
  fi
fi

# Wait for all parallel builds and fail if any failed.
for pid in "${ALL_PIDS[@]}"; do
  wait "$pid"
done

# --- Merge Android AARs ---
# If we built multiple ABIs, combine the per-ABI libgojni.so files into one AAR.
if [ "$BUILD_ANDROID" = true ] && [ "${#ANDROID_TMPDIRS[@]}" -gt 0 ]; then
  cp "${ANDROID_TMPDIRS[0]}/irmagobridge.aar" android/irmagobridge/irmagobridge.aar

  for i in $(seq 1 $(( ${#ANDROID_TMPDIRS[@]} - 1 ))); do
    merge_abi="$(get_abi "${TARGETS[$i]}")"
    TMPDIR_EXTRACT="$(mktemp -d)"
    cd "${TMPDIR_EXTRACT}"
    unzip -q "${ANDROID_TMPDIRS[$i]}/irmagobridge.aar" "jni/${merge_abi}/*"
    cd "${SCRIPT_DIR}/yivi_core"
    jar -uf android/irmagobridge/irmagobridge.aar -C "${TMPDIR_EXTRACT}" jni/
    rm -rf "${TMPDIR_EXTRACT}"
  done

  for tmpdir in "${ANDROID_TMPDIRS[@]}"; do
    rm -rf "$tmpdir"
  done
fi

# --- Symlink irma_configuration into Android assets ---
if [ "$BUILD_ANDROID" = true ] && [ ! -e "./android/src/main/assets/irma_configuration" ]; then
    case "$(uname -s)" in
      MINGW*|MSYS*|CYGWIN*)
        # Use a directory junction (no elevation needed) on Windows.
        cmd.exe /c "mklink /j \"android\\src\\main\\assets\\irma_configuration\" \"..\\..\\irma_configuration\""
        ;;
      *)
        ln -s "../../../../../irma_configuration" "./android/src/main/assets/irma_configuration"
        ;;
    esac
fi
