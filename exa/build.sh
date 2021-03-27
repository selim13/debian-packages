#!/usr/bin/env bash

app_name=exa
github_repo="ogham/exa"
revision=1
description="A modern replacement for ls"
homepage="https://the.exa.website"
license="MIT"

source ../.env
source ../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
arch=amd64
filename="exa-linux-x86_64-${version}.zip"
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

unzip -q -o -j "$filename"
install exa-linux-x86_64 "$package_name/usr/bin/exa"

fakeroot dpkg-deb --build "$package_name"    
push_deb "$package_name.deb"

rm -rf "$package_name" "$package_name.deb"
rm -f "$filename" exa-linux-x86_64

notify_updated "$app_name" "${version}-${revision}"
