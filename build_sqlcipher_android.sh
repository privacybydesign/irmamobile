#!/usr/bin/env bash
set -euo pipefail

# Cross-compile SQLCipher (with OpenSSL) as static libraries for Android.
# Produces: build/sqlcipher-android/<abi>/lib/libsqlcipher.a and include/sqlite3.h
#
# Prerequisites: ANDROID_HOME set, NDK installed.

SQLCIPHER_VERSION="4.14.0"
OPENSSL_VERSION="3.4.1"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build/sqlcipher-android"
SRC_DIR="${BUILD_DIR}/src"

NDK_VERSION="28.2.13676358"
NDK_HOME="${ANDROID_HOME}/ndk/${NDK_VERSION}"
TOOLCHAIN="${NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64"
MIN_API=26

ABIS="arm64-v8a armeabi-v7a x86_64"

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

mkdir -p "${SRC_DIR}"

# --- Download sources ---

download_openssl() {
  local archive="${SRC_DIR}/openssl-${OPENSSL_VERSION}.tar.gz"
  if [ ! -d "${SRC_DIR}/openssl-${OPENSSL_VERSION}" ]; then
    echo "==> Downloading OpenSSL ${OPENSSL_VERSION}..."
    curl -sL "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" -o "${archive}"
    tar -xzf "${archive}" -C "${SRC_DIR}"
  fi
}

download_sqlcipher() {
  local archive="${SRC_DIR}/sqlcipher-${SQLCIPHER_VERSION}.tar.gz"
  if [ ! -d "${SRC_DIR}/sqlcipher-${SQLCIPHER_VERSION}" ]; then
    echo "==> Downloading SQLCipher ${SQLCIPHER_VERSION}..."
    curl -sL "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v${SQLCIPHER_VERSION}.tar.gz" -o "${archive}"
    tar -xzf "${archive}" -C "${SRC_DIR}"
  fi
}

# --- Build OpenSSL for one ABI ---

build_openssl() {
  local abi="$1"
  local target
  target="$(get_openssl_target "$abi")"
  local prefix="${BUILD_DIR}/${abi}"

  if [ -f "${prefix}/lib/libcrypto.a" ]; then
    echo "==> OpenSSL already built for ${abi}, skipping."
    return
  fi

  echo "==> Building OpenSSL for ${abi}..."

  local work="${BUILD_DIR}/openssl-build-${abi}"
  rm -rf "${work}"
  cp -a "${SRC_DIR}/openssl-${OPENSSL_VERSION}" "${work}"
  cd "${work}"

  export ANDROID_NDK_ROOT="${NDK_HOME}"
  export PATH="${TOOLCHAIN}/bin:${PATH}"

  ./Configure "${target}" \
    -D__ANDROID_API__=${MIN_API} \
    --prefix="${prefix}" \
    no-shared \
    no-tests \
    no-ui-console \
    no-engine \
    no-async \
    2>&1 | tail -3

  make -j"$(sysctl -n hw.ncpu)" build_libs 2>&1 | tail -3
  make install_dev 2>&1 | tail -3

  cd "${SCRIPT_DIR}"
  rm -rf "${work}"
}

# --- Build SQLCipher for one ABI ---

build_sqlcipher() {
  local abi="$1"
  local triple
  triple="$(get_triple "$abi")"
  local host_triple
  host_triple="$(get_host_triple "$abi")"
  local prefix="${BUILD_DIR}/${abi}"

  if [ -f "${prefix}/lib/libsqlcipher.a" ]; then
    echo "==> SQLCipher already built for ${abi}, skipping."
    return
  fi

  echo "==> Building SQLCipher for ${abi}..."

  local work="${BUILD_DIR}/sqlcipher-build-${abi}"
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

  # Install the library and headers manually
  mkdir -p "${prefix}/lib" "${prefix}/include/sqlcipher"
  cp libsqlite3.a "${prefix}/lib/libsqlcipher.a"
  cp sqlite3.h "${prefix}/include/sqlcipher/sqlite3.h"
  cp sqlite3.h "${prefix}/include/sqlite3.h"

  cd "${SCRIPT_DIR}"
  rm -rf "${work}"
}

# --- Main ---

download_openssl
download_sqlcipher

for abi in ${ABIS}; do
  build_openssl "${abi}"
  build_sqlcipher "${abi}"
done

echo ""
echo "==> Done! Static libraries are in ${BUILD_DIR}/<abi>/lib/"
echo "    Headers are in ${BUILD_DIR}/<abi>/include/"
echo ""
echo "For each ABI you should have:"
for abi in ${ABIS}; do
  echo "  ${BUILD_DIR}/${abi}/lib/libsqlcipher.a"
  echo "  ${BUILD_DIR}/${abi}/lib/libcrypto.a"
done
