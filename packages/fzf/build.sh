#!/usr/bin/env bash

app_name=fzf
github_repo="junegunn/fzf"
revision=1
description="A command-line fuzzy finder"
homepage="https://github.com/junegunn/fzf"
license="MIT"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$tag
declare -A archs=(
    [amd64]="fzf-${version}-linux_amd64.tar.gz"
    [arm64]="fzf-${version}-linux_arm64.tar.gz"
    [armhf]="fzf-${version}-linux_armv7.tar.gz"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${version}-${revision}_${arch}"

    if deb_exists "$app_name" "${version}-${revision}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

    tmp_dir="$(mktemp -d ./package-$arch.XXXXXXXXXX)"
    cd "$tmp_dir"

    mkdir -p "$package_name/usr/bin" "$package_name/DEBIAN"

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

    tar --extract --file="$filename" fzf
    install fzf "$package_name/usr/bin/fzf"

    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    cd ..
    rm -rf "${tmp_dir}"

    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}-${revision}" || true