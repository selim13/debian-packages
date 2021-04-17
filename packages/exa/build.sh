#!/usr/bin/env bash

app_name=exa
github_repo="ogham/exa"
revision=1
description="A modern replacement for ls"
homepage="https://the.exa.website"
license="MIT"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]="exa-linux-x86_64-${tag}.zip"
    [armhf]="exa-linux-armv7-${tag}.zip"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if deb_exists "$app_name" "${version}-${revision}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

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

    unzip -q -o "$filename" -d tmp
    mkdir -p "$package_name/usr/bin/"
    install tmp/bin/exa "$package_name/usr/bin/"

    mkdir -p "$package_name/usr/share/exa/completions/"
    install -m644 tmp/completions/exa.bash "$package_name/usr/share/exa/completions/"
    install -m644 tmp/completions/exa.zsh "$package_name/usr/share/exa/completions/"
    install -m644 tmp/completions/exa.fish "$package_name/usr/share/exa/completions/"

    mkdir -p "$package_name/usr/share/man/man1/" "$package_name/usr/share/man/man5/"
    gzip -9 tmp/man/exa.1 
    gzip -9 tmp/man/exa_colors.5
    install -m644 tmp/man/exa.1.gz "$package_name/usr/share/man/man1/"
    install -m644 tmp/man/exa_colors.5.gz "$package_name/usr/share/man/man5/"

    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    rm -rf tmp "$package_name" "$package_name.deb" "$filename"        
    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}-${revision}" || true