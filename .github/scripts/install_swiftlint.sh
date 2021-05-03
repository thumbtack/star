#!/bin/bash

# Installs the SwiftLint package.
# Tries to install from Homebrew, but if that fails just recompiles from source.

set -e

if command -v swiftlint; then exit 0; fi

echo "Installing SwiftLint from Homebrew..."
brew update && brew install swiftlint
if command -v swiftlint; then exit 0; fi

echo "Failed to install SwiftLint from Homebrew. Compiling from source..."
swiftlint_repo_path=$(mktemp swiftlint.XXXX)
git clone https://github.com/realm/SwiftLint.git $swiftlint_repo_path
cd $swiftlint_repo_path
git submodule update --init --recursive
make install

