#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQLCIPHER_DIR="${SCRIPT_DIR}/build/sqlcipher-android"

get_abi() {
  case "$1" in
    android/arm64) echo "arm64-v8a" ;;
    android/arm)   echo "armeabi-v7a" ;;
    android/amd64) echo "x86_64" ;;
  esac
}

cd yivi_core

# --- Android: build per-ABI to link the correct static SQLCipher ---

FIRST=true
for target in android/arm64 android/arm android/amd64; do
  abi="$(get_abi "$target")"
  prefix="${SQLCIPHER_DIR}/${abi}"

  if [ ! -f "${prefix}/lib/libsqlcipher.a" ]; then
    echo "ERROR: SQLCipher not built for ${abi}. Run build_sqlcipher_android.sh first."
    exit 1
  fi

  echo "==> Building gomobile for ${target} (${abi})..."

  export CGO_CFLAGS="-I${prefix}/include -I${prefix}/include/sqlcipher"
  export CGO_LDFLAGS="-L${prefix}/lib"

  if [ "$FIRST" = true ]; then
    gomobile bind -target "${target}" -androidapi 26 \
      -o android/irmagobridge/irmagobridge.aar \
      github.com/privacybydesign/irmamobile/irmagobridge
    FIRST=false
  else
    # Build subsequent ABIs into temp AARs, then merge the .so into the main AAR
    TMPDIR_AAR="$(mktemp -d)"
    TMPAAR="${TMPDIR_AAR}/irmagobridge.aar"
    gomobile bind -target "${target}" -androidapi 26 \
      -o "${TMPAAR}" \
      github.com/privacybydesign/irmamobile/irmagobridge

    # Extract the jni/<abi>/libgojni.so from the temp AAR and add to the main one
    TMPDIR_EXTRACT="$(mktemp -d)"
    cd "${TMPDIR_EXTRACT}"
    unzip -q "${TMPAAR}" "jni/*"
    cd "${SCRIPT_DIR}/yivi_core"
    # Add the new ABI's .so to the existing AAR
    jar -uf android/irmagobridge/irmagobridge.aar -C "${TMPDIR_EXTRACT}" jni/
    rm -rf "${TMPDIR_EXTRACT}" "${TMPDIR_AAR}"
  fi

  unset CGO_CFLAGS CGO_LDFLAGS
done

# --- iOS: use pkg-config (SQLCipher provided via CocoaPods) ---
gomobile bind -target ios -iosversion 15.6 -o ios/Irmagobridge.xcframework \
  github.com/privacybydesign/irmamobile/irmagobridge

# On Windows, create a directory junction for irma_configuration on Android, on Linux-style systems a symlink.
if [ ! -e "./android/src/main/assets/irma_configuration" ]; then
    if [[ "$OSTYPE" == "msys"* ]]; then
        cmd.exe <<<$"mklink /j .\android\src\main\assets\irma_configuration .\..\irma_configuration"
    else
        ln -s "../../../../../irma_configuration" "./android/src/main/assets/irma_configuration"
    fi
fi
