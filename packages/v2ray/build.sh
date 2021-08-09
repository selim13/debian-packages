#!/usr/bin/env bash

github_repo="v2fly/v2ray-core"
app_name=v2ray
revision=1
description="A platform for building proxies to bypass network restrictions."
homepage="https://github.com/v2fly/v2ray-core"
license="MIT"

source ../../functions.sh
set -e

tag=$(github_latest_tag $github_repo)
version=$(echo $tag | sed s/v//)
package_version="${version}-${revision}"
declare -A archs=(
    [amd64]=v2ray-linux-64.zip
    [arm64]=v2ray-linux-arm64-v8a.zip
    [armhf]=v2ray-linux-arm32-v7a.zip
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}    
    package_name="${app_name}_${package_version}_${arch}"

    if deb_exists "$app_name" "${package_version}" "$arch"; then
        echo "$package_name already in repository"
        continue
    fi

    mkdir -p tmp
    cd tmp

    mkdir -p "$package_name/DEBIAN"

    echo "Package: ${app_name}" > "$package_name/DEBIAN/control"
    echo "Version: ${package_version}" >> "$package_name/DEBIAN/control"
    echo "Section: custom" >> "$package_name/DEBIAN/control"
    echo "Priority: optional" >> "$package_name/DEBIAN/control"
    echo "Architecture: ${arch}" >> "$package_name/DEBIAN/control"
    echo "Essential: no" >> "$package_name/DEBIAN/control"
    echo "Maintainer: Dmitry Seleznyov <selim013@gmail.com>" >> "$package_name/DEBIAN/control"
    echo "Description: ${description}" >> "$package_name/DEBIAN/control"
    echo "Homepage: ${homepage}" >> "$package_name/DEBIAN/control"
    echo "License: ${license}" >> "$package_name/DEBIAN/control"

    curl --silent --location "https://github.com/${github_repo}/releases/download/${tag}/${filename}" --output "$filename"
    unzip -q -o "$filename" -d .

    install -Dm755 v2ctl -t "$package_name/usr/bin/"
    install -Dm755 v2ray -t "$package_name/usr/bin/"
    install -Dm644 config.json -t "$package_name/etc/v2ray/"
    install -Dm644 vpoint_socks_vmess.json -t "$package_name/etc/v2ray/"
    install -Dm644 vpoint_vmess_freedom.json -t "$package_name/etc/v2ray/"
    install -Dm644 geoip.dat -t "$package_name/usr/share/v2ray/"
    install -Dm644 geosite.dat -t "$package_name/usr/share/v2ray/"
    install -Dm644 systemd/system/v2ray.service -t "$package_name/etc/systemd/system/"
    install -Dm644 systemd/system/v2ray@.service -t "$package_name/etc/systemd/system/"

    sed -i 's!/usr/local/bin/!/usr/bin/!g' "$package_name/etc/systemd/system/v2ray.service"
    sed -i 's!/usr/local/etc/!/etc/!g' "$package_name/etc/systemd/system/v2ray.service"
    sed -i 's!/usr/local/bin/!/usr/bin/!g' "$package_name/etc/systemd/system/v2ray@.service"
    sed -i 's!/usr/local/etc/!/etc/!g' "$package_name/etc/systemd/system/v2ray@.service"


    fakeroot dpkg-deb --build "$package_name"
    push_deb "$package_name.deb"

    cd ..
    rm -rf tmp

    updated=true
done

[ ! -z $updated ] && notify_updated "$app_name" "$package_version" || true