#!/usr/bin/env bash

app_name=lf
github_repo="gokcehan/lf"
revision=1
description="Terminal file manager"
homepage="https://github.com/gokcehan/lf"
license="MIT"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/r//)
declare -A archs=(
    [amd64]="lf-linux-amd64.tar.gz"
    [arm64]="lf-linux-arm64.tar.gz"
    [armhf]="lf-linux-arm.tar.gz"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}-${revision}_${arch}"

    if deb_exists "$app_name" "${version}-${revision}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

    mkdir -p "$package_name/DEBIAN" "$package_name/usr/bin"
    
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

    tar --extract --file="$filename" lf
    install lf "$package_name/usr/bin/lf"
    
    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    rm -rf "$package_name" "$package_name.deb" "$filename" lf    

    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}-${revision}" || true