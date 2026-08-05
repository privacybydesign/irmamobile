#!/usr/bin/env bash
set -euxo pipefail

# =============================================================================
# fdroid_build.sh — Build the F-Droid APK the way the F-Droid buildserver does.
#
# This is the `build:` step of the org.irmacard.cardemu recipe in
# https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.irmacard.cardemu.yml
# It used to be inlined there, duplicated per release and impossible to test
# without a full buildserver run. It lives here so the recipe can call it and so
# a change to the build only needs a change in this repository.
#
# Why this exists at all: bind_go.sh normally downloads prebuilt static
# SQLCipher + OpenSSL libraries from a GitHub release. F-Droid does not allow
# prebuilt binaries, so this script cross-compiles both from source (from the
# OpenSSL and sqlcipher srclibs) into build/sqlcipher-prebuilt/android/<abi>,
# which is exactly where bind_go.sh looks. Finding them there, bind_go.sh skips
# the download and links against them.
#
# Usage:
#   FLUTTER_DIR=... GO_SRC_DIR=... OPENSSL_SRC_DIR=... SQLCIPHER_SRC_DIR=... \
#     ANDROID_NDK_HOME=... ./yivi_fdroid/fdroid_build.sh
#
# In the F-Droid recipe those values are srclib/NDK placeholders, which only
# expand inside the .yml, so the recipe has to pass them in:
#
#   build:
#     - FLUTTER_DIR=$$flutter$$ GO_SRC_DIR=$$go$$ OPENSSL_SRC_DIR=$$OpenSSL$$
#       SQLCIPHER_SRC_DIR=$$sqlcipher$$ ANDROID_NDK_HOME=$$NDK$$
#       bash fdroid_build.sh
#
# Required environment:
#   FLUTTER_DIR        Flutter SDK checkout ($$flutter$$)
#   GO_SRC_DIR         Go source checkout, built from source here ($$go$$)
#   OPENSSL_SRC_DIR    OpenSSL source checkout ($$OpenSSL$$)
#   SQLCIPHER_SRC_DIR  SQLCipher source checkout ($$sqlcipher$$)
#   ANDROID_NDK_HOME   Android NDK ($$NDK$$)
#
# Also needed, and provided by the recipe's `sudo:` and `prebuild:` steps:
#   - build-essential, tcl, unzip and a bootstrap Go (to run go's make.bash)
#   - `flutter pub get` already run in this directory
# =============================================================================

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"

# F-Droid buildservers are Debian x86_64; the NDK ships one toolchain per host.
NDK_HOST_TAG="linux-x86_64"

# Minimum supported Android API level. Must match the -androidapi passed to
# gomobile in bind_go.sh, otherwise the static libs and libgojni.so disagree.
ANDROID_API=26

# The ABIs bind_go.sh builds, so every one of them needs its own static libs.
ABIS=(arm64-v8a armeabi-v7a x86_64)

# Where bind_go.sh expects to find the static libs.
PREBUILT_DIR="$ROOT/build/sqlcipher-prebuilt/android"

# Scratch copies of the srclibs. We build out of a copy because both configure
# scripts write into their source tree, and a srclib is shared between builds.
OPENSSL_BUILD_DIR="$ROOT/bo"
SQLCIPHER_BUILD_DIR="$ROOT/bs"

require_env() {
  local missing=()
  local name
  for name in "$@"; do
    if [ -z "${!name:-}" ]; then
      missing+=("$name")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: missing required environment variables: ${missing[*]}" >&2
    echo "See the header of $0 for what each one should point at." >&2
    exit 1
  fi
}

require_env FLUTTER_DIR GO_SRC_DIR OPENSSL_SRC_DIR SQLCIPHER_SRC_DIR ANDROID_NDK_HOME

# --- Per-ABI toolchain mapping ---------------------------------------------
# Every ABI names itself three different ways: the NDK clang wrapper prefix, the
# autoconf --host value and OpenSSL's own target name. They are not
# interchangeable, and armeabi-v7a is the one where all three differ.

abi_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android" ;;
    armeabi-v7a) echo "armv7a-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android" ;;
    *) echo "Unknown ABI: $1" >&2; exit 1 ;;
  esac
}

abi_host_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android" ;;
    armeabi-v7a) echo "arm-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android" ;;
    *) echo "Unknown ABI: $1" >&2; exit 1 ;;
  esac
}

abi_openssl_target() {
  case "$1" in
    arm64-v8a)   echo "android-arm64" ;;
    armeabi-v7a) echo "android-arm" ;;
    x86_64)      echo "android-x86_64" ;;
    *) echo "Unknown ABI: $1" >&2; exit 1 ;;
  esac
}

# =============================================================================
# Build Go from source. F-Droid cannot ship the official toolchain, so the go
# srclib is a source checkout that make.bash turns into a usable toolchain,
# bootstrapped by the distro Go the recipe installs.
# =============================================================================

echo "==> Building the Go toolchain from source"
(cd "$GO_SRC_DIR/src" && ./make.bash)

export GOROOT="$GO_SRC_DIR"
export GOPATH="$APP_DIR/golang"
# Stop the toolchain from downloading a different Go than the one we just built.
export GOTOOLCHAIN=local
export PATH="$GO_SRC_DIR/bin:$GOPATH/bin:$PATH"

# gomobile and the Android Gradle plugin read both spellings, depending on version.
export ANDROID_NDK_HOME
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"

TC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST_TAG"
export PATH="$TC/bin:$PATH"

# =============================================================================
# Cross-compile OpenSSL and SQLCipher for every ABI.
# =============================================================================

build_openssl() {
  local abi="$1" prefix="$2"
  local openssl_target
  # Assign on its own line so an unknown ABI aborts here, instead of handing
  # Configure an empty target and building for the host.
  openssl_target="$(abi_openssl_target "$abi")"
  echo "==> Building OpenSSL for $abi"

  rm -rf "$OPENSSL_BUILD_DIR"
  cp -a "$OPENSSL_SRC_DIR" "$OPENSSL_BUILD_DIR"

  (
    cd "$OPENSSL_BUILD_DIR"
    ./Configure "$openssl_target" \
      "-D__ANDROID_API__=$ANDROID_API" \
      --prefix="$prefix" \
      no-shared no-tests no-ui-console no-engine no-async
    # build_libs + install_dev: we only need libcrypto.a and its headers, not
    # the apps or the docs.
    make -j"$(nproc)" build_libs
    make install_dev
  )
}

build_sqlcipher() {
  local abi="$1" prefix="$2"
  local triple host_triple
  triple="$(abi_triple "$abi")"
  host_triple="$(abi_host_triple "$abi")"
  echo "==> Building SQLCipher for $abi"

  rm -rf "$SQLCIPHER_BUILD_DIR"
  cp -a "$SQLCIPHER_SRC_DIR" "$SQLCIPHER_BUILD_DIR"

  (
    cd "$SQLCIPHER_BUILD_DIR"
    CC="$TC/bin/${triple}${ANDROID_API}-clang" \
    AR="$TC/bin/llvm-ar" \
    RANLIB="$TC/bin/llvm-ranlib" \
    ./configure \
      --host="$host_triple" \
      --prefix="$prefix" \
      --disable-shared \
      --with-tempstore=yes \
      --disable-tcl \
      CFLAGS="-DSQLITE_HAS_CODEC -DSQLCIPHER_CRYPTO_OPENSSL -DSQLITE_TEMP_STORE=2 -DSQLITE_EXTRA_INIT=sqlcipher_extra_init -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown -I$prefix/include" \
      LDFLAGS="-L$prefix/lib -lcrypto"
    make -j"$(nproc)" libsqlite3.a

    # `make install` would also install the shell and the tcl bits, so place
    # the pieces bind_go.sh needs by hand. SQLCipher's amalgamation is named
    # libsqlite3.a but the linker flag in bind_go.sh is -lsqlcipher.
    mkdir -p "$prefix/lib" "$prefix/include/sqlcipher"
    cp libsqlite3.a "$prefix/lib/libsqlcipher.a"
    cp sqlite3.h "$prefix/include/sqlite3.h"
    cp sqlite3.h "$prefix/include/sqlcipher/sqlite3.h"
  )
}

for ABI in "${ABIS[@]}"; do
  PREFIX="$PREBUILT_DIR/$ABI"
  build_openssl "$ABI" "$PREFIX"
  build_sqlcipher "$ABI" "$PREFIX"
done

# bind_go.sh passes one -I for all ABIs (the headers are identical), so give it
# a single include directory alongside the per-ABI lib directories.
echo "==> Publishing the shared include directory"
# Remove it first: `cp -a src dst` on an existing dst would nest the headers as
# include/include, which only shows up as a compile error on the second run.
rm -rf "$PREBUILT_DIR/include"
cp -a "$PREBUILT_DIR/${ABIS[0]}/include" "$PREBUILT_DIR/include"

# =============================================================================
# Build the Go bridge and the APK.
# =============================================================================

echo "==> Building the Go bridge"
(cd "$ROOT" && bash ci_scripts/install_gomobile.sh)
(cd "$ROOT" && bash bind_go.sh android)

echo "==> Building the APK"
# Keep the pub cache inside this directory so the recipe's `scandelete:` entry
# for yivi_fdroid/.pub-cache can clean it up before the APK is scanned.
export PUB_CACHE="$APP_DIR/.pub-cache"
(cd "$APP_DIR" && "$FLUTTER_DIR/bin/flutter" build apk --flavor beta)
