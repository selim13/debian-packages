function preflight_check() {
    local binaries=(curl dpkg-deb fakeroot gpg jq reprepro tar unzip)
    for binary in "${binaries[@]}"; do
        >/dev/null command -v "$binary" || { log_error "$binary is not installed"; exit 1; }
    done

    local variables=(
        REPREPRO_BASE_PATH
        PUBLIC_PATH
        REPO_PATH
        REPO_CODENAME
    )
    for var in "${variables[@]}"; do
        [ -z "${!var}" ] && { log_error "\$${var} is not set"; exit 1; }
    done

    if [ ! -z "$GPG_KEY" ]; then
        if ! $(gpg --list-keys --keyid-format=long | grep --word-regexp --quiet $GPG_KEY); then
            log_error "$GPG_KEY is not found"
            exit 1
        fi
    fi 

    mkdir -p "$REPREPRO_BASE_PATH" "$PUBLIC_PATH" "$REPO_PATH"
}

function configure_reprepro {
    local file="$REPREPRO_BASE_PATH/conf/distributions"
    [ -f "$file" ] && return;

    echo -n "" > "$file";
    [ ! -z "$REPO_ORIGIN" ] && echo "Origin: $REPO_ORIGIN" >> "$file"
    [ ! -z "$REPO_SUITE" ] && echo "Suite: $REPO_SUITE" >> "$file"
    [ ! -z "$REPO_CODENAME" ] && echo "Codename: $REPO_CODENAME" >> "$file"
    [ ! -z "$REPO_ARCHITECTURES" ] && echo "Architectures: $REPO_ARCHITECTURES" >> "$file"
    [ ! -z "$REPO_COMPONENTS" ] && echo "Components: $REPO_COMPONENTS" >> "$file"
    [ ! -z "$REPO_DESCRIPTION" ] && echo "Description: $REPO_DESCRIPTION" >> "$file"
    [ ! -z "$GPG_KEY" ] && echo "SignWith: $GPG_KEY" >> "$file"    
}


tg_send_message() {
    if [[ -z "$TG_TOKEN" || -z "$TG_CHAT_ID" ]]; then
        return
    fi

    local message="$1"
    local url="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"

    curl --silent --request POST "$url" --data chat_id="$TG_CHAT_ID" --data parse_mode="HTML" --data text="$message" > /dev/null
}

tg_send_update() {
    local name="$1"
    local message="$2"

    local br="%0A"
    tg_send_message "✅ <a href='http://deb.selim13.ru'>deb.selim13.ru</a>${br}${br}<b>${name}</b>${br}${message}"    
}

tg_send_error() {
    local name="$1"
    local message="$2"

    local br="%0A"
    tg_send_message "❌ <a href='http://deb.selim13.ru'>deb.selim13.ru</a>${br}${br}<b>${name}</b>${br}${message}"    
}

deb_exists() {
    local name="$1"
    local version="$2"
    local arch="$3"
    
    [ ! -z "$(reprepro --basedir "$REPREPRO_BASE_PATH" --outdir "$REPO_PATH" listfilter $REPO_CODENAME "Package (== $name), Version (== $version), Architecture (== $arch)")" ]
}

push_deb() {
    local filename="$1"

    reprepro --basedir "$REPREPRO_BASE_PATH" --outdir "$REPO_PATH" includedeb sid "$filename"    
}

notify_updated() {
    local name="$1"
    local version="$2"

    tg_send_update "$name" "$version"
}

log_info() {
    local msg="$@"

    echo "$@"

    if [ ! -z "$INFO_LOG" ]; then
        echo "$@" >> "$INFO_LOG"
    fi
}

log_error() {
    local msg="$@"

    >&2 echo "$@"

    if [ ! -z "$ERROR_LOG" ]; then
        echo "$@" >> "$ERROR_LOG"
    fi
}

github_latest_tag() {
    local github_repo="$1"    
    local api_url="https://api.github.com/repos/${github_repo}/releases/latest"

    curl --silent "$api_url" | jq --raw-output ".tag_name"
}