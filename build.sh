#!/usr/bin/env bash

[ -f .env ] && set -o allexport && source .env set && set +o allexport
source ./functions.sh

mkdir -p "$REPREPRO_BASE_PATH" "$PUBLIC_PATH" "$REPOSITORY_PATH"

declare -a packages=(
    docker-ctop
    exa
    fd
    fnm
    gping
    lando
    oha
    psysh
    ripgrep
    starship
    wp-cli
)

for package in "${packages[@]}"; do
    if result=$((cd packages/$package; ./build.sh) 2>&1); then
        log_info "Building $package"
        log_info "$result"
        log_info ""
    else
        log_error "$package"
        log_error "$result"
        log_error ""

        tg_send_error "$package" "$result"
        exit 1
    fi
done