#!/usr/bin/env bash
set -euxo pipefail

# We assume that Golang is already installed.
if [ ! -x "$(command -v "go")" ]; then
  echo "Go not installed"
  exit 1
fi

if ! [ -x "$(command -v "gomobile")" ]; then
  # By not specifying a specific gomobile version, we ensure that the version we pinned in go.mod is used.
  go install golang.org/x/mobile/cmd/gomobile
  gomobile init
fi
