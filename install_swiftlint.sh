#!/bin/bash

# Installs the SwiftLint package.
# Tries to get the precompiled .pkg file from Github, but if that
# fails just recompiles from source.

set -e

swiftlint_pkg_path=$(mktemp)
SWIFTLINT_PKG_URL="https://github.com/realm/SwiftLint/releases/download/0.39.2/SwiftLint.pkg"

curl $SWIFTLINT_PKG_URL -o $swiftlint_pkg_path

if [ -f $SWIFTLINT_PKG_PATH ]; then
    echo "SwiftLint package exists! Installing it..."
    sudo installer -pkg $swiftlint_pkg_path -target /
else
    echo "SwiftLint package doesn't exist. Compiling from source..." &&
    swiftlint_repo_path=$(mktemp) &&
    git clone https://github.com/realm/SwiftLint.git $swiftlint_repo_path &&
    cd $swiftlint_repo_path &&
    git submodule update --init --recursive &&
    sudo make install
fi
