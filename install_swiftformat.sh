#!/bin/bash

# Installs the SwiftFormat package.
# Tries to get the precompiled .pkg file from Github, but if that
# fails just recompiles from source.

set -e

brew update && brew install swiftformat

if ! type swiftformat >/dev/null 2>&1; then
    echo "SwiftFormat package doesn't exist. Compiling from source..." &&
    git clone https://github.com/nicklockwood/SwiftFormat.git /tmp/SwiftFormat &&
    cd /tmp/SwiftFormat &&
    git submodule update --init --recursive &&
    swift build -c release &&
    install .build/release/swiftformat /usr/local/bin
fi
