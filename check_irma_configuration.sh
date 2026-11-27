#!/usr/bin/env bash
# Stops a build that would ship without schemes.
#
# The schemes in irma_configuration/ are git submodules. `git clone` without
# --recursive and `git worktree add` leave them as empty directories. The app
# then builds fine, but cannot start: it shows the "IRMA wordt Yivi" screen,
# whose button does nothing, and later "expected default keyshare scheme pbdf
# could not be found in configuration". This script fails early instead.
#
# Called by bind_go.sh and the iOS Podfile; the Android build checks the same
# in yivi_core/android/build.gradle.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

missing=()
while read -r _ path; do
  # Every scheme carries a signed index; an empty checkout has none.
  [ -f "$ROOT/$path/index" ] || missing+=("$path")
done < <(git config --file "$ROOT/.gitmodules" --get-regexp '^submodule\..*\.path$' | grep ' irma_configuration/')

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "error: these schemes in irma_configuration/ are not checked out:"
    printf '         %s\n' "${missing[@]}"
    echo
    echo "       They are git submodules, which 'git clone' without --recursive and"
    echo "       'git worktree add' leave empty. An app built without them cannot start"
    echo "       (\"expected default keyshare scheme pbdf could not be found in"
    echo "       configuration\"). Check them out with:"
    echo
    echo "         git -C \"$ROOT\" submodule update --init"
  } >&2
  exit 1
fi
