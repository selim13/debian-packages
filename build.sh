#!/usr/bin/env bash

set -e

declare -a packages=(
    fnm
    lando
    ripgrep
    starship
)

for package in "${packages[@]}"; do
    (cd $package; ./build.sh)
done