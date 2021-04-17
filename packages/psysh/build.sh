#!/usr/bin/env bash

app_name=psysh
github_repo="bobthecow/psysh"
revision=1
description="A runtime developer console, interactive debugger and REPL for PHP"
homepage="https://psysh.org"
license="MIT"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [all]="psysh-${tag}-compat.tar.gz"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}-${revision}_${arch}"

    if deb_exists "$app_name" "${version}-${revision}" "$arch"; then
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
    
    tar --extract --file="$filename" --directory="$package_name/usr/bin" psysh    
    chmod 755 "$package_name/usr/bin/psysh"

    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    rm -rf "$package_name" "$package_name.deb"
    rm -f "$filename"

    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}-${revision}" || true