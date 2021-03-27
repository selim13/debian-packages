#!/usr/bin/env bash

app_name=fnm
github_repo="Schniz/fnm"
revision=1
description="Fast and simple Node.js version manager, built in Rust"
homepage="https://github.com/Schniz/fnm"
license="GPL3"

source ../.env
source ../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]=fnm-linux.zip
    [arm64]=fnm-arm64.zip
    [arm32]=fnm-arm32.zip
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}-${revision}_${arch}"

    if deb_exists "$package_name"; then
        echo "$package_name already in repository"
        continue
    fi

    mkdir -p "$package_name"
    mkdir -p "$package_name/usr/bin"
    mkdir -p "$package_name/DEBIAN"

    echo "Package: ${app_name}" > "$package_name/DEBIAN/control"
    echo "Version: ${version}-${revision}" >> "$package_name/DEBIAN/control"
    echo "Section: custom" >> "$package_name/DEBIAN/control"
    echo "Priority: optional" >> "$package_name/DEBIAN/control"
    echo "Architecture: ${arch}" >> "$package_name/DEBIAN/control"
    echo "Essential: no" >> "$package_name/DEBIAN/control"
    echo "Maintainer: Dmitry Seleznyov <selim013@gmail.com>" >> "$package_name/DEBIAN/control"
    echo "Description: ${description}" >> "$package_name/DEBIAN/control"
    echo "Homepage: ${homepage}" >> "$package_name/DEBIAN/control"
    echo "License: ${license}" >> "$package_name/DEBIAN/control"

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    unzip -q -o -j -d "$package_name/usr/bin" $filename
    chmod 755 "$package_name/usr/bin/fnm"

    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    rm -rf "$package_name" "$package_name.deb"
    rm -f "$filename"

    updated=true
done

if [ ! -z $updated ]; then
    notify_updated "$app_name" "${version}-${revision}"
fi