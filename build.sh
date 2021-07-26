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
    fzf
    gping
    lando
    lf
    oha
    psysh
    ripgrep
    spotify-adblock
    starship
    vidir
    wp-cli
)

if [ $# -gt 0 ]; then
    build=$@
else
    build=${packages[@]}
fi

for package in $build; do
    [ ! -d "packages/$package" ] && echo "Build script for $package not found" && exit 1

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