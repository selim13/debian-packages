#!/usr/bin/env bash

app_name="spotify-adblock"
github_repo="abba23/spotify-adblock"
revision=1
epoch=1 # spotify-adblock restarted numeration system after rewrite on rust
description="Spotify adblocker for Linux"
homepage="https://github.com/abba23/spotify-adblock"
license="GPL3"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
declare -A archs=(
    [amd64]="spotify-adblock.so"
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${app_name}_${epoch}:${version}-${revision}_${arch}"

    if deb_exists "$app_name" "${epoch}:${version}-${revision}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

    mkdir -p "$package_name/DEBIAN" 

    echo "Package: ${app_name}" > "$package_name/DEBIAN/control"
    echo "Version: ${epoch}:${version}-${revision}" >> "$package_name/DEBIAN/control"
    echo "Section: custom" >> "$package_name/DEBIAN/control"
    echo "Priority: optional" >> "$package_name/DEBIAN/control"
    echo "Architecture: ${arch}" >> "$package_name/DEBIAN/control"
    echo "Essential: no" >> "$package_name/DEBIAN/control"
    echo "Maintainer: Dmitry Seleznyov <selim013@gmail.com>" >> "$package_name/DEBIAN/control"
    echo "Description: ${description}" >> "$package_name/DEBIAN/control"
    echo "Homepage: ${homepage}" >> "$package_name/DEBIAN/control"
    echo "License: ${license}" >> "$package_name/DEBIAN/control"

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    curl --silent --location "https://raw.githubusercontent.com/abba23/spotify-adblock/${tag}/config.toml" --output "config.toml"

    mkdir -p "$package_name/usr/lib/"
    install -m644 spotify-adblock.so "$package_name/usr/lib/"

    mkdir -p "$package_name/usr/bin/"
    install bin/spotify-adblock "$package_name/usr/bin/"

    mkdir -p "$package_name/usr/share/applications/"
    install spotify-adblock.desktop "$package_name/usr/share/applications/"
    
    mkdir -p "$package_name/etc/spotify-adblock/"
    install config.toml "$package_name/etc/spotify-adblock/"

    fakeroot dpkg-deb --build "$package_name"    
    push_deb "$package_name.deb"

    rm -rf spotify-adblock.so config.toml "$package_name" "$package_name.deb" "$filename"        
    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "${version}-${revision}" || true