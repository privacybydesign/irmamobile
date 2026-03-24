#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# bind_go.sh — Build the Go bridge (irmagobridge) for Android and iOS.
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
# gomobile bind builds all ABIs in a single invocation, but each ABI needs
# different -I/-L flags pointing to its own static libs. Since gomobile does
# not support per-ABI CGO flags, we invoke it once per ABI and merge the
# resulting AARs.
#
# Prerequisites:
#   - Go, gomobile (see ci_scripts/install_gomobile.sh)
#   - ANDROID_HOME set, NDK installed
#   - Xcode (for iOS)
#   - pkg-config + sqlcipher (brew install sqlcipher) for iOS host linking
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQLCIPHER_DIR="${SCRIPT_DIR}/build/sqlcipher-android"

SQLCIPHER_VERSION="4.14.0"
OPENSSL_VERSION="3.4.1"
SRC_DIR="${SQLCIPHER_DIR}/src"
NDK_VERSION="28.2.13676358"
NDK_HOME="${ANDROID_HOME}/ndk/${NDK_VERSION}"
TOOLCHAIN="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64"
MIN_API=26

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
  for abi in arm64-v8a armeabi-v7a x86_64; do
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

  for abi in arm64-v8a armeabi-v7a x86_64; do
    build_openssl "${abi}"
    build_sqlcipher "${abi}"
  done

  echo "==> SQLCipher static libraries ready."
}

# =============================================================================
# Build the Go bridge with gomobile bind.
# =============================================================================

ensure_sqlcipher_libs

cd yivi_core

# --- Android ---
# Build each ABI separately so we can pass the correct -I/-L flags for that
# ABI's static SQLCipher. The first invocation creates the AAR; subsequent
# ones build into temp AARs and we merge their libgojni.so into the first.

FIRST=true
for target in android/arm64 android/arm android/amd64; do
  abi="$(get_abi "$target")"
  prefix="${SQLCIPHER_DIR}/${abi}"

  echo "==> Building gomobile for ${target} (${abi})..."

  export CGO_CFLAGS="-I${prefix}/include -I${prefix}/include/sqlcipher"
  export CGO_LDFLAGS="-L${prefix}/lib"

  if [ "$FIRST" = true ]; then
    gomobile bind -target "${target}" -androidapi 26 \
      -o android/irmagobridge/irmagobridge.aar \
      github.com/privacybydesign/irmamobile/irmagobridge
    FIRST=false
  else
    # Build this ABI into a temporary AAR, then copy its .so into the main AAR.
    TMPDIR_AAR="$(mktemp -d)"
    TMPAAR="${TMPDIR_AAR}/irmagobridge.aar"
    gomobile bind -target "${target}" -androidapi 26 \
      -o "${TMPAAR}" \
      github.com/privacybydesign/irmamobile/irmagobridge

    TMPDIR_EXTRACT="$(mktemp -d)"
    cd "${TMPDIR_EXTRACT}"
    unzip -q "${TMPAAR}" "jni/*"
    cd "${SCRIPT_DIR}/yivi_core"
    jar -uf android/irmagobridge/irmagobridge.aar -C "${TMPDIR_EXTRACT}" jni/
    rm -rf "${TMPDIR_EXTRACT}" "${TMPDIR_AAR}"
  fi

  unset CGO_CFLAGS CGO_LDFLAGS
done

# --- iOS ---
# On iOS, SQLCipher is provided as a CocoaPods dependency (see yivi_core.podspec).
# The #cgo directive in sqlcipher.go uses pkg-config to find the host sqlcipher
# headers at compile time; CocoaPods links the actual library at app build time.
gomobile bind -target ios -iosversion 15.6 -o ios/Irmagobridge.xcframework \
  github.com/privacybydesign/irmamobile/irmagobridge

# --- Symlink irma_configuration into Android assets ---
if [ ! -e "./android/src/main/assets/irma_configuration" ]; then
    if [[ "$OSTYPE" == "msys"* ]]; then
        cmd.exe <<<$"mklink /j .\android\src\main\assets\irma_configuration .\..\irma_configuration"
    else
        ln -s "../../../../../irma_configuration" "./android/src/main/assets/irma_configuration"
    fi
fi
