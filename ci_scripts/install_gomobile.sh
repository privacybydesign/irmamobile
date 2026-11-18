#!/usr/bin/env bash
set -euxo pipefail

# We assume that Golang is already installed.
if [ ! -x "$(command -v "go")" ]; then
  echo "Go not installed"
  exit 1
fi

cd yivi_core
# By not specifying a specific gomobile version, we ensure that the version we pinned in go.mod is used.
#
# We install unconditionally rather than only when gomobile is missing: CI caches ~/go/bin under a
# key that does not include yivi_core/go.mod, so a gomobile built from an older pin would otherwise
# be restored and silently keep being used. Both steps are cheap when nothing changed — `go install`
# hits the build cache, and `gomobile init` only recreates $GOPATH/pkg/gomobile.
go install golang.org/x/mobile/cmd/gomobile
gomobile init
