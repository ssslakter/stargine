#!/usr/bin/env bash
set -euo pipefail

EXAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$EXAMPLES_DIR")"
NAME="${1:-}"

if [ -z "$NAME" ] || [ ! -f "$EXAMPLES_DIR/$NAME/main.mojo" ]; then
    echo "usage: pixi run example <name>" >&2
    echo -n "available examples:" >&2
    for candidate in "$EXAMPLES_DIR"/*/main.mojo; do
        echo -n " $(basename "$(dirname "$candidate")")" >&2
    done
    echo >&2
    exit 1
fi

cd "$PROJECT_DIR"
ROOT_DIR=stargine EXAMPLE_DIR="examples/$NAME" mojo -I . "examples/$NAME/main.mojo"
