#!/usr/bin/env bash

app_name=fd
github_repo="sharkdp/fd"

source ../.env
source ../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]=fd_${version}_amd64.deb
    [i386]=fd_${version}_i386.deb
    [arm32]=fd_${version}_armhf.deb
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if deb_exists "$package_name"; then
        echo "$package_name already in repository"
        continue
    fi

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    
    push_deb "$filename"

    rm -f "$filename"
    updated=true
done

if [ ! -z $updated ]; then
    notify_updated "$app_name" "$version"
fi