#!/usr/bin/env bash

set -e

app_name=fnm
revision=2

api_url="https://api.github.com/repos/Schniz/fnm/releases/latest"
tag=$(curl -s $api_url | jq -r '.name')
version=$(echo $tag | sed s/v//)

declare -A archs=(
    [amd64]=fnm-linux.zip
    [arm64]=fnm-arm64.zip
    [arm32]=fnm-arm32.zip
)

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

    echo "Package: fnm" > "$package_name/DEBIAN/control"
    echo "Version: ${version}-${revision}" >> "$package_name/DEBIAN/control"
    echo "Section: custom" >> "$package_name/DEBIAN/control"
    echo "Priority: optional" >> "$package_name/DEBIAN/control"
    echo "Architecture: $arch" >> "$package_name/DEBIAN/control"
    echo "Essential: no" >> "$package_name/DEBIAN/control"
    echo "Maintainer: Dmitry Seleznyov <selim013@gmail.com>" >> "$package_name/DEBIAN/control"
    echo "Description: Fast and simple Node.js version manager, built in Rust" >> "$package_name/DEBIAN/control"

    wget -O $filename "https://github.com/Schniz/fnm/releases/download/${tag}/${filename}"
    unzip -o -j -d "$package_name/usr/bin" $filename
    chmod 755 "$package_name/usr/bin/fnm"

    dpkg-deb --build "$package_name"
    aptly repo add deb-cli "$package_name.deb"

    rm -rf "$package_name" "$package_name.deb"
    rm -f "$filename"
done