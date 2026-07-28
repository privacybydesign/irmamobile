#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# fdroid_build_test.sh — Test fdroid_build.sh without a buildserver.
#
# A real run needs the Android NDK, four srclib checkouts and about an hour of
# cross-compiling, so nobody ever ran the F-Droid build script before pushing it
# to fdroiddata. Instead this builds a fake repository and a fake toolchain
# (stub Configure/configure/make/flutter/... that record how they were called),
# runs fdroid_build.sh against them and asserts on the recorded calls and on the
# layout of build/sqlcipher-prebuilt/android, which is the contract with
# bind_go.sh.
#
# Usage: ./yivi_fdroid/fdroid_build_test.sh
# =============================================================================

SCRIPT_UNDER_TEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fdroid_build.sh"

FAILURES=0

fail() {
  echo "  FAIL: $*" >&2
  FAILURES=$((FAILURES + 1))
}

assert_file() {
  if [ ! -f "$1" ]; then
    fail "expected file $1"
  fi
}

assert_contains() {
  local file="$1" needle="$2"
  if ! grep -qF -- "$needle" "$file"; then
    fail "expected $(basename "$file") to contain: $needle"
    echo "  --- $file ---" >&2
    sed 's/^/  /' "$file" >&2
  fi
}

# -----------------------------------------------------------------------------
# Build a fake repository, srclibs and NDK in $WORK.
# -----------------------------------------------------------------------------

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
CALLS="$WORK/calls.log"
STUB_BIN="$WORK/stub-bin"
NDK="$WORK/ndk"
GO_SRC="$WORK/srclib/go"
OPENSSL_SRC="$WORK/srclib/openssl"
SQLCIPHER_SRC="$WORK/srclib/sqlcipher"
FLUTTER="$WORK/srclib/flutter"

mkdir -p "$REPO/yivi_fdroid" "$REPO/ci_scripts" "$STUB_BIN" \
  "$GO_SRC/src" "$OPENSSL_SRC" "$SQLCIPHER_SRC" "$FLUTTER/bin"

cp "$SCRIPT_UNDER_TEST" "$REPO/yivi_fdroid/fdroid_build.sh"

# The real NDK toolchain, reduced to the binaries the build script names.
NDK_TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
mkdir -p "$NDK_TC"
for tool in aarch64-linux-android26-clang armv7a-linux-androideabi26-clang \
  x86_64-linux-android26-clang llvm-ar llvm-ranlib; do
  printf '#!/bin/sh\nexit 0\n' > "$NDK_TC/$tool"
  chmod +x "$NDK_TC/$tool"
done

# `make.bash` stands in for building the Go toolchain from source.
cat > "$GO_SRC/src/make.bash" <<EOF
#!/bin/sh
echo "make.bash cwd=\$(pwd)" >> "$CALLS"
EOF
chmod +x "$GO_SRC/src/make.bash"

# OpenSSL's Configure. Records its arguments and leaves the --prefix behind for
# the stub make, which needs to know where install_dev should write.
cat > "$OPENSSL_SRC/Configure" <<EOF
#!/bin/sh
echo "openssl Configure \$*" >> "$CALLS"
for arg in "\$@"; do
  case "\$arg" in
    --prefix=*) echo "\${arg#--prefix=}" > .stub_prefix ;;
  esac
done
EOF
chmod +x "$OPENSSL_SRC/Configure"

# SQLCipher's configure. Records the cross-compiler handed to it as well, since
# picking the wrong one per ABI is the mistake this build is prone to.
cat > "$SQLCIPHER_SRC/configure" <<EOF
#!/bin/sh
echo "sqlcipher configure CC=\$CC AR=\$AR RANLIB=\$RANLIB \$*" >> "$CALLS"
touch .stub_configured
EOF
chmod +x "$SQLCIPHER_SRC/configure"

# One stub make for both projects; it tells them apart by the target.
cat > "$STUB_BIN/make" <<EOF
#!/bin/sh
target=""
for arg in "\$@"; do
  case "\$arg" in
    -j*) ;;
    *) target="\$arg" ;;
  esac
done
echo "make \$target cwd=\$(basename "\$(pwd)")" >> "$CALLS"
prefix=""
[ -f .stub_prefix ] && prefix="\$(cat .stub_prefix)"
case "\$target" in
  build_libs)
    touch libcrypto.a
    ;;
  install_dev)
    [ -n "\$prefix" ] || { echo "install_dev without a prefix" >&2; exit 1; }
    mkdir -p "\$prefix/include/openssl" "\$prefix/lib"
    touch "\$prefix/include/openssl/ssl.h" "\$prefix/lib/libcrypto.a"
    ;;
  libsqlite3.a)
    [ -f .stub_configured ] || { echo "make before configure" >&2; exit 1; }
    touch libsqlite3.a sqlite3.h
    ;;
  *)
    echo "unexpected make target: \$target" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$STUB_BIN/make"

cat > "$FLUTTER/bin/flutter" <<EOF
#!/bin/sh
echo "flutter \$* cwd=\$(basename "\$(pwd)") PUB_CACHE=\$PUB_CACHE" >> "$CALLS"
EOF
chmod +x "$FLUTTER/bin/flutter"

cat > "$REPO/ci_scripts/install_gomobile.sh" <<EOF
#!/bin/sh
echo "install_gomobile GOROOT=\$GOROOT GOTOOLCHAIN=\$GOTOOLCHAIN" >> "$CALLS"
EOF

# The real bind_go.sh looks for the static libs where this build script puts
# them; record what it would have found.
cat > "$REPO/bind_go.sh" <<EOF
#!/bin/sh
echo "bind_go \$1 NDK=\$ANDROID_NDK_HOME/\$ANDROID_NDK_ROOT" >> "$CALLS"
for abi in arm64-v8a armeabi-v7a x86_64; do
  [ -f "build/sqlcipher-prebuilt/android/\$abi/lib/libsqlcipher.a" ] \
    || { echo "bind_go: no libsqlcipher.a for \$abi" >&2; exit 1; }
done
[ -f build/sqlcipher-prebuilt/android/include/sqlite3.h ] \
  || { echo "bind_go: no shared sqlite3.h" >&2; exit 1; }
[ -f build/sqlcipher-prebuilt/android/include/sqlcipher/sqlite3.h ] \
  || { echo "bind_go: no sqlcipher/sqlite3.h" >&2; exit 1; }
EOF

run_build() {
  env -i \
    PATH="$STUB_BIN:/usr/bin:/bin" \
    HOME="$WORK/home" \
    FLUTTER_DIR="$FLUTTER" \
    GO_SRC_DIR="$GO_SRC" \
    OPENSSL_SRC_DIR="$OPENSSL_SRC" \
    SQLCIPHER_SRC_DIR="$SQLCIPHER_SRC" \
    ANDROID_NDK_HOME="$NDK" \
    "$@"
}

# -----------------------------------------------------------------------------
echo "test: a missing srclib path is reported instead of building half an APK"
# -----------------------------------------------------------------------------

missing_output="$WORK/missing.log"
if env -i PATH="$STUB_BIN:/usr/bin:/bin" HOME="$WORK/home" \
  FLUTTER_DIR="$FLUTTER" GO_SRC_DIR="$GO_SRC" ANDROID_NDK_HOME="$NDK" \
  bash "$REPO/yivi_fdroid/fdroid_build.sh" > "$missing_output" 2>&1; then
  fail "expected a non-zero exit when OPENSSL_SRC_DIR and SQLCIPHER_SRC_DIR are unset"
fi
assert_contains "$missing_output" "OPENSSL_SRC_DIR SQLCIPHER_SRC_DIR"

# -----------------------------------------------------------------------------
echo "test: a full build produces what bind_go.sh and the recipe expect"
# -----------------------------------------------------------------------------

build_output="$WORK/build.log"
if ! run_build bash "$REPO/yivi_fdroid/fdroid_build.sh" > "$build_output" 2>&1; then
  fail "the build script exited non-zero"
  sed 's/^/  /' "$build_output" >&2
fi

PREBUILT="$REPO/build/sqlcipher-prebuilt/android"

for abi in arm64-v8a armeabi-v7a x86_64; do
  assert_file "$PREBUILT/$abi/lib/libsqlcipher.a"
  assert_file "$PREBUILT/$abi/lib/libcrypto.a"
  assert_file "$PREBUILT/$abi/include/sqlite3.h"
  assert_file "$PREBUILT/$abi/include/sqlcipher/sqlite3.h"
done

# bind_go.sh passes a single -I for all ABIs, so this shared copy has to exist.
assert_file "$PREBUILT/include/sqlite3.h"
assert_file "$PREBUILT/include/sqlcipher/sqlite3.h"

# Each ABI must get its own OpenSSL target and its own clang wrapper.
assert_contains "$CALLS" "openssl Configure android-arm64 -D__ANDROID_API__=26 --prefix=$PREBUILT/arm64-v8a"
assert_contains "$CALLS" "openssl Configure android-arm -D__ANDROID_API__=26 --prefix=$PREBUILT/armeabi-v7a"
assert_contains "$CALLS" "openssl Configure android-x86_64 -D__ANDROID_API__=26 --prefix=$PREBUILT/x86_64"
assert_contains "$CALLS" "CC=$NDK_TC/aarch64-linux-android26-clang AR=$NDK_TC/llvm-ar RANLIB=$NDK_TC/llvm-ranlib --host=aarch64-linux-android"
assert_contains "$CALLS" "CC=$NDK_TC/armv7a-linux-androideabi26-clang AR=$NDK_TC/llvm-ar RANLIB=$NDK_TC/llvm-ranlib --host=arm-linux-androideabi"
assert_contains "$CALLS" "CC=$NDK_TC/x86_64-linux-android26-clang AR=$NDK_TC/llvm-ar RANLIB=$NDK_TC/llvm-ranlib --host=x86_64-linux-android"

# Without these defines SQLCipher builds as plain unencrypted SQLite and the
# wallet database silently stops being encrypted, so pin them exactly.
assert_contains "$CALLS" "CFLAGS=-DSQLITE_HAS_CODEC -DSQLCIPHER_CRYPTO_OPENSSL -DSQLITE_TEMP_STORE=2 -DSQLITE_EXTRA_INIT=sqlcipher_extra_init -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown -I$PREBUILT/arm64-v8a/include"
assert_contains "$CALLS" "LDFLAGS=-L$PREBUILT/x86_64/lib -lcrypto"

# The Go toolchain is built from source, and nothing may download another one.
assert_contains "$CALLS" "make.bash cwd=$GO_SRC/src"
assert_contains "$CALLS" "install_gomobile GOROOT=$GO_SRC GOTOOLCHAIN=local"

# bind_go.sh runs from the repository root, where build/sqlcipher-prebuilt is.
assert_contains "$CALLS" "bind_go android NDK=$NDK/$NDK"

# The APK is the beta flavour, built in yivi_fdroid with the local pub cache
# that the recipe's scandelete entry cleans up.
assert_contains "$CALLS" "flutter build apk --flavor beta cwd=yivi_fdroid PUB_CACHE=$REPO/yivi_fdroid/.pub-cache"

# The scratch source copies must not be reused between ABIs; a stale configured
# tree would silently link the previous ABI's libcrypto.
if [ -f "$REPO/bs/.stub_configured" ] && [ "$(grep -c 'sqlcipher configure' "$CALLS")" -ne 3 ]; then
  fail "expected configure to run once per ABI"
fi

# -----------------------------------------------------------------------------
echo "test: a second run leaves the same layout behind"
# -----------------------------------------------------------------------------

rerun_output="$WORK/rerun.log"
if ! run_build bash "$REPO/yivi_fdroid/fdroid_build.sh" > "$rerun_output" 2>&1; then
  fail "the build script exited non-zero on a second run"
  sed 's/^/  /' "$rerun_output" >&2
fi

assert_file "$PREBUILT/include/sqlite3.h"
if [ -e "$PREBUILT/include/include" ]; then
  fail "the shared include directory was nested inside itself on the second run"
fi

# -----------------------------------------------------------------------------

if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES check(s) failed" >&2
  exit 1
fi
echo "all checks passed"
