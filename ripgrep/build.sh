#!/usr/bin/env bash

github_repo="BurntSushi/ripgrep"
app_name=ripgrep

source ../.env
source ../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
declare -A archs=(
    [amd64]="ripgrep_${tag}_amd64.deb"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if deb_exists "$package_name"; then
        echo "$package_name already in repository"
        continue
    fi

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    push_deb "$package_name.deb"
    rm -f "$filename"

    updated=true
done

if [ ! -z $updated ]; then
    notify_updated "$app_name" "${version}-${revision}"
fi