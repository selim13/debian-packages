tg_send_message() {
    if [[ -z "$TG_TOKEN" || -z "$TG_CHAT_ID" ]]; then
        echo 'Skipping telegram: missing $TG_TOKEN or $TG_CHAT_ID'
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
    local package_name="$1"

    [ ! -z "$(aptly package show ${package_name})" ]
}

push_deb() {
    local filename="$1"
    aptly repo add deb-cli "$filename"
}

notify_updated() {
    local name="$1"
    local version="$2"

    tg_send_update "$name" "$version"
}

log_info() {
    local msg="$@"

    echo "$@"

    if [[ ! -z "$INFO_LOG" ]]; then
        echo "$@" >> "$INFO_LOG"
    fi
}

log_error() {
    local msg="$@"

    >&2 echo "$@"

    if [[ ! -z "$ERROR_LOG" ]]; then
        echo "$@" >> "$ERROR_LOG"
    fi
}

github_latest_tag() {
    local github_repo="$1"    
    local api_url="https://api.github.com/repos/${github_repo}/releases/latest"

    curl --silent "$api_url" | jq --raw-output ".tag_name"
}