#!/usr/bin/env bash

app_name=lando
github_repo="lando/lando"

source ../.env
source ../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]="lando-${tag}.deb"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}_${arch}"

    if deb_exists "$package_name"; then
        echo "$package_name already in repository"
        continue
    fi

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"    
    push_deb "$package_name.deb"
    rm -f "$package_name.deb"

    updated=true
done

if [ ! -z $updated ]; then
    notify_updated "$app_name" "${version}-${revision}"
fi