#!/bin/bash

# Installs the SwiftLint package.
# Tries to get the precompiled .pkg file from Github, but if that
# fails just recompiles from source.

set -e

brew update && brew install swiftlint

if ! type swiftformat > /dev/null 2>&1; then
    echo "SwiftLint package doesn't exist. Compiling from source..." &&
    swiftlint_repo_path=$(mktemp) &&
    git clone https://github.com/realm/SwiftLint.git $swiftlint_repo_path &&
    cd $swiftlint_repo_path &&
    git submodule update --init --recursive &&
    sudo make install
fi
