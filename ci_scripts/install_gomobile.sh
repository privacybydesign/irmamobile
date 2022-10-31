#!/usr/bin/env bash
set -euxo pipefail

# We assume that Golang is already installed.
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
