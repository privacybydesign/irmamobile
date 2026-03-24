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
# On Android, there is no package manager for native libs, so we must
# cross-compile SQLCipher (and its dependency OpenSSL) as static libraries
# and link them into libgojni.so ourselves.
#
# The static libraries are cached in build/sqlcipher-android/ and only built
# once. Delete that directory to force a rebuild (e.g. after a version bump).
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
SQLCIPHER_DIR="${SCRIPT_DIR}/build/sqlcipher-android"

SQLCIPHER_VERSION="4.14.0"
OPENSSL_VERSION="3.4.1"
SRC_DIR="${SQLCIPHER_DIR}/src"
NDK_VERSION="28.2.13676358"
NDK_HOME="${ANDROID_HOME}/ndk/${NDK_VERSION}"
TOOLCHAIN="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64"
MIN_API=26

ABIS="arm64-v8a armeabi-v7a x86_64"

# --- ABI mapping helpers ---

get_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android" ;;
    armeabi-v7a) echo "armv7a-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android" ;;
  esac
}

get_openssl_target() {
  case "$1" in
    arm64-v8a)   echo "android-arm64" ;;
    armeabi-v7a) echo "android-arm" ;;
    x86_64)      echo "android-x86_64" ;;
  esac
}

get_host_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android" ;;
    armeabi-v7a) echo "arm-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android" ;;
  esac
}

get_abi() {
  case "$1" in
    android/arm64) echo "arm64-v8a" ;;
    android/arm)   echo "armeabi-v7a" ;;
    android/amd64) echo "x86_64" ;;
  esac
}

# =============================================================================
# Cross-compile OpenSSL as a static library for one Android ABI.
# SQLCipher uses OpenSSL's libcrypto for its encryption routines.
# =============================================================================
build_openssl() {
  local abi="$1"
  local target
  target="$(get_openssl_target "$abi")"
  local prefix="${SQLCIPHER_DIR}/${abi}"

  if [ -f "${prefix}/lib/libcrypto.a" ]; then
    return
  fi

  echo "==> Building OpenSSL ${OPENSSL_VERSION} for ${abi}..."

  local work="${SQLCIPHER_DIR}/openssl-build-${abi}"
  rm -rf "${work}"
  cp -a "${SRC_DIR}/openssl-${OPENSSL_VERSION}" "${work}"
  cd "${work}"

  export ANDROID_NDK_ROOT="${NDK_HOME}"
  export PATH="${TOOLCHAIN}/bin:${PATH}"

  ./Configure "${target}" \
    -D__ANDROID_API__=${MIN_API} \
    --prefix="${prefix}" \
    no-shared no-tests no-ui-console no-engine no-async \
    2>&1 | tail -3

  make -j"$(sysctl -n hw.ncpu)" build_libs 2>&1 | tail -3
  make install_dev 2>&1 | tail -3

  cd "${SCRIPT_DIR}"
  rm -rf "${work}"
}

# =============================================================================
# Cross-compile SQLCipher as a static library for one Android ABI.
#
# We only build the static library (libsqlite3.a), not the CLI shell, because
# the shell tries to link against zlib/readline which aren't available in the
# NDK sysroot. The library is renamed to libsqlcipher.a so the linker flag
# -lsqlcipher (from sqlcipher.go's #cgo android LDFLAGS) resolves correctly.
# =============================================================================
build_sqlcipher() {
  local abi="$1"
  local triple
  triple="$(get_triple "$abi")"
  local host_triple
  host_triple="$(get_host_triple "$abi")"
  local prefix="${SQLCIPHER_DIR}/${abi}"

  if [ -f "${prefix}/lib/libsqlcipher.a" ]; then
    return
  fi

  echo "==> Building SQLCipher ${SQLCIPHER_VERSION} for ${abi}..."

  local work="${SQLCIPHER_DIR}/sqlcipher-build-${abi}"
  rm -rf "${work}"
  cp -a "${SRC_DIR}/sqlcipher-${SQLCIPHER_VERSION}" "${work}"
  cd "${work}"

  local cc="${TOOLCHAIN}/bin/${triple}${MIN_API}-clang"
  local ar="${TOOLCHAIN}/bin/llvm-ar"
  local ranlib="${TOOLCHAIN}/bin/llvm-ranlib"

  CC="${cc}" AR="${ar}" RANLIB="${ranlib}" \
  ./configure \
    --host="${host_triple}" \
    --prefix="${prefix}" \
    --disable-shared \
    --with-tempstore=yes \
    --disable-tcl \
    CFLAGS="-DSQLITE_HAS_CODEC \
            -DSQLCIPHER_CRYPTO_OPENSSL \
            -DSQLITE_TEMP_STORE=2 \
            -DSQLITE_EXTRA_INIT=sqlcipher_extra_init \
            -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown \
            -I${prefix}/include" \
    LDFLAGS="-L${prefix}/lib -lcrypto" \
    2>&1 | tail -5

  make -j"$(sysctl -n hw.ncpu)" libsqlite3.a 2>&1 | tail -3

  mkdir -p "${prefix}/lib" "${prefix}/include/sqlcipher"
  cp libsqlite3.a "${prefix}/lib/libsqlcipher.a"
  cp sqlite3.h "${prefix}/include/sqlcipher/sqlite3.h"
  cp sqlite3.h "${prefix}/include/sqlite3.h"

  cd "${SCRIPT_DIR}"
  rm -rf "${work}"
}

# =============================================================================
# Ensure static SQLCipher + OpenSSL libs exist for all Android ABIs.
# This is a one-time build; subsequent runs skip it entirely.
# =============================================================================
ensure_sqlcipher_libs() {
  local needs_build=false
  for abi in ${ABIS}; do
    if [ ! -f "${SQLCIPHER_DIR}/${abi}/lib/libsqlcipher.a" ] || \
       [ ! -f "${SQLCIPHER_DIR}/${abi}/lib/libcrypto.a" ]; then
      needs_build=true
      break
    fi
  done

  if [ "$needs_build" = false ]; then
    return
  fi

  echo "==> SQLCipher static libraries not found, building (one-time)..."
  mkdir -p "${SRC_DIR}"

  if [ ! -d "${SRC_DIR}/openssl-${OPENSSL_VERSION}" ]; then
    echo "==> Downloading OpenSSL ${OPENSSL_VERSION}..."
    curl -sL "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" \
      | tar -xzf - -C "${SRC_DIR}"
  fi

  if [ ! -d "${SRC_DIR}/sqlcipher-${SQLCIPHER_VERSION}" ]; then
    echo "==> Downloading SQLCipher ${SQLCIPHER_VERSION}..."
    curl -sL "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v${SQLCIPHER_VERSION}.tar.gz" \
      | tar -xzf - -C "${SRC_DIR}"
  fi

  for abi in ${ABIS}; do
    build_openssl "${abi}"
    build_sqlcipher "${abi}"
  done

  echo "==> SQLCipher static libraries ready."
}

# =============================================================================
# Build the Go bridge with gomobile bind.
#
# All gomobile invocations (Android ABIs + iOS) run in parallel.
# After all builds complete, the per-ABI Android AARs are merged into one.
# =============================================================================

if [ "$BUILD_ANDROID" = true ]; then
  ensure_sqlcipher_libs
fi

cd yivi_core

# --- Helper: build one Android ABI into an AAR ---
build_android_abi() {
  local target="$1"
  local outfile="$2"
  local abi
  abi="$(get_abi "$target")"
  local prefix="${SQLCIPHER_DIR}/${abi}"

  echo "==> Building gomobile for ${target} (${abi})..."

  CGO_CFLAGS="-I${prefix}/include -I${prefix}/include/sqlcipher" \
  CGO_LDFLAGS="-L${prefix}/lib" \
  gomobile bind -target "${target}" -androidapi 26 \
    -o "${outfile}" \
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
    TMPDIR_EXTRACT="$(mktemp -d)"
    cd "${TMPDIR_EXTRACT}"
    unzip -q "${ANDROID_TMPDIRS[$i]}/irmagobridge.aar" "jni/*"
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
    if [[ "$OSTYPE" == "msys"* ]]; then
        cmd.exe <<<$"mklink /j .\android\src\main\assets\irma_configuration .\..\irma_configuration"
    else
        ln -s "../../../../../irma_configuration" "./android/src/main/assets/irma_configuration"
    fi
fi
