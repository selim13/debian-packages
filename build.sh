#!/usr/bin/env bash

[ -f .env ] && set -o allexport && source .env set && set +o allexport
source ./functions.sh

preflight_check
configure_reprepro

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
    log_info "Building $package"
    if result=$((cd packages/$package; ./build.sh) 2>&1); then
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

key_file="$REPO_PATH/repo.gpg.key"
[[ ! -z "$GPG_KEY" && ! -f "$key_file" ]] && gpg --export --armor "$GPG_KEY" > "$key_file"

(cd site; yarn build)