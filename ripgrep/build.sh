#!/usr/bin/env bash

github_repo="BurntSushi/ripgrep"
app_name=ripgrep

set -e

api_url="https://api.github.com/repos/${github_repo}/releases/latest"
tag=$(curl -s $api_url | jq -r '.name')

declare -A archs=(
    [amd64]=ripgrep_${tag}_amd64.deb
)

for arch in "${!archs[@]}"; do
    filename=${archs[$arch]}
    package_name="${filename%.*}"

    if [ ! -z "$(aptly package show ${package_name})" ]; then
        echo "${filename%.*} already in repository"
        continue
    fi

    wget -O "${filename}" "https://github.com/${github_repo}/releases/download/${tag}/${filename}"
    
    aptly repo add deb-cli "$filename"
    rm -f "$filename"
done