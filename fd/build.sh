#!/usr/bin/env bash

set -e

github_repo="sharkdp/fd"
api_url="https://api.github.com/repos/${github_repo}/releases/latest"
tag=$(curl -s $api_url | jq -r '.name')
version=$(echo $tag | sed s/v//)

declare -A archs=(
    [amd64]=fd_${version}_amd64.deb
    [i386]=fd_${version}_i386.deb
    [arm32]=fd_${version}_armhf.deb
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if [ ! -z "$(aptly package show ${package_name})" ]; then
        echo "${filename%.*} already in repository"
        continue
    fi

    wget -O "${filename}" "https://github.com/${github_repo}/releases/download/${tag}/${filename}"
    
    aptly repo add deb-cli "$filename"
    rm -f "$filename"
done