#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$TESTS_DIR")"
NAME="${1:-}"

if [ -z "$NAME" ] || [ ! -d "$TESTS_DIR/$NAME" ]; then
    echo "usage: pixi run test <example>" >&2
    echo "available examples: $(cd "$TESTS_DIR" && ls -d */ | tr -d / | tr '\n' ' ')" >&2
    exit 1
fi

cd "$PROJECT_DIR"
ROOT_DIR=stargine TEST_DIR="tests/$NAME" mojo -I . "tests/$NAME/main.mojo"
