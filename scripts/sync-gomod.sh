#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
LIB_DIR="$DIR/../.bootstrap/shell/lib"

# shellcheck source=../.bootstrap/shell/lib/logging.sh
source "$LIB_DIR/logging.sh"

run_sed() {
  case "$OSTYPE" in
  darwin*) # macOS
    sed -i '' -e "$@"
    ;;
  linux*)
    sed -i -e "$@"
    ;;
  esac
}

gomodGoVersion="$(grep "^go " go.mod | awk '{print $2}')"
gomodToolchainVersion="$(grep "^toolchain " go.mod | awk '{print $2}')"
goboxVersion="$(grep "getoutreach/gobox " go.mod | awk '{print $2}')"

if [[ -z $gomodGoVersion ]]; then
  fatal "go version not found in go.mod"
fi

if [[ -z $gomodToolchainVersion ]]; then
  fatal "toolchain version not found in go.mod"
fi

if [[ -z $goboxVersion ]]; then
  fatal "gobox version not found in go.mod"
fi

info "Go version: $gomodGoVersion"
info "Toolchain version: $gomodToolchainVersion"
info "gobox version: $goboxVersion"

run_sed "s/^go .*$/go $gomodGoVersion/" pkg/go.mod
run_sed "s/^toolchain .*$/toolchain $gomodToolchainVersion/" pkg/go.mod
run_sed "s:\(\tgithub.com/getoutreach/gobox\) .*:\1 $goboxVersion:" pkg/go.mod
