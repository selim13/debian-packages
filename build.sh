#!/usr/bin/env bash

source .env
source ./functions.sh

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
)

for package in "${packages[@]}"; do
    if result=$((cd $package; ./build.sh) 2>&1); then
        log_info "$package"
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