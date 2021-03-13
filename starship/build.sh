#!/usr/bin/env bash

github_repo="starship/starship"
app_name=starship
revision=1
description="The minimal, blazing-fast, and infinitely customizable prompt for any shell!"
homepage="https://starship.rs"
license="GPL3"

declare -A archs=(
    [amd64]=starship-x86_64-unknown-linux-musl.tar.gz
    [i386]=starship-i686-unknown-linux-musl.tar.gz
    [arm64]=starship-aarch64-unknown-linux-musl.tar.gz
    [arm32]=starship-arm-unknown-linux-musleabihf.tar.gz
)

##########
set -e

api_url="https://api.github.com/repos/${github_repo}/releases/latest"
tag=$(curl -s $api_url | jq -r '.name')
version=$(echo $tag | sed s/v//)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}-${revision}_${arch}"

    if [ ! -z "$(aptly package show ${package_name})" ]; then
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


    wget -O "$filename" "https://github.com/${github_repo}/releases/download/${tag}/${filename}"
    tar --extract --file="$filename" --directory="$package_name/usr/bin" starship
    chmod 755 "$package_name/usr/bin/starship"

    dpkg-deb --build "$package_name"
    aptly repo add deb-cli "$package_name.deb"

    rm -rf "$package_name" "$package_name.deb"
    rm -f "$filename"
done