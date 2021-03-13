#!/usr/bin/env bash

set -e

app_name=lando

api_url="https://api.github.com/repos/lando/lando/releases/latest"
tag=$(curl -s $api_url | jq -r '.name')
version=$(echo $tag | sed s/v//)

declare -A archs=(
    [amd64]=lando-${tag}.deb
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}_${arch}"

    if [ ! -z "$(aptly package show ${package_name})" ]; then
        echo "$package_name already in repository"
        continue
    fi

    wget -O "${package_name}.deb" "https://github.com/lando/lando/releases/download/${tag}/${filename}"
    
    aptly repo add deb-cli "$package_name.deb"
    rm -f "$package_name.deb"
done