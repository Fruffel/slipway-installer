#!/bin/sh
# Public launcher only. Installation code and binaries remain in private Gitea.
set +x
set -eu
umask 077

fail() { printf '%s\n' "slipway download: $*" >&2; exit 1; }

main() {
    if [ "${1:-}" = --help ] || [ "${1:-}" = -h ]; then
        printf '%s\n' 'Usage: curl -fsSL https://raw.githubusercontent.com/Fruffel/slipway-installer/main/install.sh | sudo sh -s -- [install options]'
        printf '%s\n' 'Prompts once for a Gitea read:repository token and saves it privately for later downloads.'
        exit 0
    fi
    [ "$(id -u)" = 0 ] || fail 'run as root'
    [ "$(uname -s)" = Linux ] || fail 'Linux is required'
    for tool in curl mktemp stat stty; do
        command -v "$tool" >/dev/null 2>&1 || fail "required command is missing: $tool"
    done
    for parent in / /etc; do
        [ ! -L "$parent" ] && [ -d "$parent" ] && [ "$(stat -c %u "$parent")" = 0 ] || fail 'unsafe credential parent'
        parent_mode=$(stat -c %a "$parent")
        [ "$((0$parent_mode & 022))" -eq 0 ] || fail 'credential parent is writable by other users'
    done
    if [ ! -e /etc/slipway ] && [ ! -L /etc/slipway ]; then mkdir -m 700 /etc/slipway; fi
    [ ! -L /etc/slipway ] && [ -d /etc/slipway ] && [ "$(stat -c '%u:%a' /etc/slipway)" = '0:700' ] || fail 'credential directory must be root-owned mode0700'
    credential=/etc/slipway/release-header
    legacy=/root/.slipway-release-header
    if [ -e "$credential" ] || [ -L "$credential" ]; then
        [ ! -L "$credential" ] && [ -f "$credential" ] && [ "$(stat -c '%u:%a' "$credential")" = '0:600' ] || fail 'saved credential must be a regular root-owned mode0600 file'
        header=$credential
    elif [ -e "$legacy" ] || [ -L "$legacy" ]; then
        [ ! -L /root ] && [ -d /root ] && [ "$(stat -c %u /root)" = 0 ] || fail 'unsafe legacy credential directory'
        root_mode=$(stat -c %a /root)
        [ "$((0$root_mode & 022))" -eq 0 ] || fail 'legacy credential directory is writable by other users'
        [ ! -L "$legacy" ] && [ -f "$legacy" ] && [ "$(stat -c '%u:%a' "$legacy")" = '0:600' ] || fail 'legacy credential must be a regular root-owned mode0600 file'
        header=$legacy
    else
        header=
    fi
    download_dir=$(mktemp -d /tmp/slipway-launcher.XXXXXXXXXX)
    tty_mode=
    trap '[ -z "$tty_mode" ] || stty "$tty_mode" < /dev/tty; rm -rf -- "$download_dir"' EXIT
    trap 'exit 1' HUP INT TERM
    if [ -z "$header" ]; then
        tty_mode=$(stty -g < /dev/tty 2>/dev/null) || fail 'a terminal is required for the first token prompt'
        stty -echo < /dev/tty
        printf 'Gitea token (read:repository; saved for later downloads): ' > /dev/tty
        IFS= read -r release_token < /dev/tty || fail 'could not read token'
        stty "$tty_mode" < /dev/tty
        tty_mode=
        printf '\n' > /dev/tty
        case "$release_token" in ''|*[!a-fA-F0-9]*) fail 'expected a 40-character Gitea personal access token' ;; esac
        [ "${#release_token}" = 40 ] || fail 'expected a 40-character Gitea personal access token'
        header="$download_dir/header"
        printf 'Authorization: token %s\n' "$release_token" > "$header"
        unset release_token
    fi
    curl -q --header "@$header" --proto '=https' --proto-redir '=https' --tlsv1.2 -fLsS \
        --connect-timeout 15 --max-time 600 \
        'https://git.bqa-solutions.nl/jeroen/slipway/releases/download/latest/install.sh' \
        -o "$download_dir/install.sh" 2>/dev/null || fail 'release download failed; check token permissions and server access'
    sh -n "$download_dir/install.sh" 2>/dev/null || fail 'downloaded installer is invalid'
    case "$(cat "$download_dir/install.sh")" in
        *"credential=$credential"*) ;;
        *) fail 'latest private release needs /etc/slipway token support (v0.1.2 or newer)' ;;
    esac
    if [ "$header" != "$credential" ]; then
        # Do not overwrite a file created by another installer in the meantime.
        (set -C; cat "$header" > "$credential") || fail 'could not save credential'
        [ "$header" != "$legacy" ] || rm -- "$legacy" || fail 'could not remove migrated legacy credential'
        printf '%s\n' 'slipway download: token saved privately; rerun this command for later release downloads'
    fi
    sh "$download_dir/install.sh" "$@"
}

main "$@"
