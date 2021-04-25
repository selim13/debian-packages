#!/usr/bin/env bash

app_name=vidir
github_repo="trapd00r/vidir"
revision=1
description='Edit directory in $EDITOR (better than vim . with netrw) '
homepage="https://github.com/trapd00r/vidir"
license="GPL3"

source ../../.env
source ../../functions.sh
set -e

mkdir -p tmp
git clone https://github.com/trapd00r/vidir tmp/vidir

version="$(grep --perl-regexp --only-matching "VERSION = '\K[0-9\.]+" tmp/vidir/bin/vidir)"
[ ! -z "$version" ]

arch=all
package_name="${app_name}_${version}-${revision}_${arch}"

if deb_exists "$app_name" "${version}-${revision}" "$arch"; then
    echo "$package_name already in repository"
    rm -rf tmp
    exit
fi

build_dir="tmp/$package_name"
mkdir -p "$build_dir/usr/bin" "$build_dir/DEBIAN"

echo "Package: ${app_name}" > "$build_dir/DEBIAN/control"
echo "Version: ${version}-${revision}" >> "$build_dir/DEBIAN/control"
echo "Section: custom" >> "$build_dir/DEBIAN/control"
echo "Priority: optional" >> "$build_dir/DEBIAN/control"
echo "Architecture: ${arch}" >> "$build_dir/DEBIAN/control"
echo "Essential: no" >> "$build_dir/DEBIAN/control"
echo "Maintainer: Dmitry Seleznyov <selim013@gmail.com>" >> "$build_dir/DEBIAN/control"
echo "Description: ${description}" >> "$build_dir/DEBIAN/control"
echo "Homepage: ${homepage}" >> "$build_dir/DEBIAN/control"
echo "License: ${license}" >> "$build_dir/DEBIAN/control"


install tmp/vidir/bin/vidir "$build_dir/usr/bin/vidir"
fakeroot dpkg-deb --build "$build_dir"    
push_deb "tmp/$package_name.deb"

rm -rf tmp
notify_updated "$app_name" "${version}-${revision}"