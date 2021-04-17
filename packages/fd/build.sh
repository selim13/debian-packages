#!/usr/bin/env bash

app_name=fd
github_repo="sharkdp/fd"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]=fd_${version}_amd64.deb
    [i386]=fd_${version}_i386.deb
    [armhf]=fd_${version}_armhf.deb
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if deb_exists "$app_name" "${version}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    
    push_deb "$filename"

    rm -f "$filename"
    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}" || true