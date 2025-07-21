#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"/../ || exit 1
export ROOT_DIR=$1
mojo -I . "$1/main.mojo"
