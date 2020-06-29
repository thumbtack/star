#!/bin/bash

# Installs the SwiftLint package.
# Tries to get the precompiled .pkg file from Github, but if that
# fails just recompiles from source.

set -e

SWIFTLINT_PKG_PATH="/tmp/SwiftLint.pkg"
SWIFTLINT_PKG_URL="https://github.com/realm/SwiftLint/releases/download/0.39.2/SwiftLint.pkg"

curl $SWIFTLINT_PKG_URL -o $SWIFTLINT_PKG_PATH

if [ -f $SWIFTLINT_PKG_PATH ]; then
    echo "SwiftLint package exists! Installing it..."
    sudo installer -pkg $SWIFTLINT_PKG_PATH -target /
else
    echo "SwiftLint package doesn't exist. Compiling from source..." &&
    git clone https://github.com/realm/SwiftLint.git /tmp/SwiftLint &&
    cd /tmp/SwiftLint &&
    git submodule update --init --recursive &&
    sudo make install
fi
