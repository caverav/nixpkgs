#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=./. -i bash -p jq

set -euo pipefail

DEFAULT_NIX="$(realpath "./pkgs/applications/editors/android-studio/default.nix")"
RELEASES_JSON="$(curl --silent -L https://jb.gg/android-studio-releases-list.json)"

# Available channels: Release/Patch (stable), Beta, Canary
getLatestRelease() {
    local channel="$1"
    case "$channel" in
        "stable") local select='.channel == "Release" or .channel == "Patch"' ;;
        "beta") local select='.channel == "Beta" or .channel == "RC"' ;;
        *) local select=".channel == \"${channel^}\"" ;;
    esac
    local result="$(echo "$RELEASES_JSON" \
        | jq -r ".content.item[] | select(${select}) | first(.download[] | select(.link | test(\"linux\\\\.tar\\\\.gz$\"))) as \$linux | [.version, .name, \$linux.link, \$linux.checksum] | @tsv" \
        | sort --version-sort \
        | tail -n 1)"

    if [[ -n "$result" ]]; then
        echo "$result"
    else
        echo "could not find the latest release for $channel"
        exit 1
    fi
}

updateChannel() {
    local channel="$1"
    local latestRelease="$(getLatestRelease "$channel")"
    local latestVersion="$(cut -f1 <<<"$latestRelease")"
    local latestName="$(cut -f2 <<<"$latestRelease")"
    local latestUrl="$(cut -f3 <<<"$latestRelease")"
    local latestChecksum="$(cut -f4 <<<"$latestRelease")"

    local localVersion="$(nix --extra-experimental-features nix-command eval --raw --file . androidStudioPackages."${channel}".version)"
    if [[ "${latestVersion}" == "${localVersion}" ]]; then
        echo "$channel is already up to date at $latestVersion"
        return 0
    fi
    echo "updating $channel from $localVersion to $latestVersion"

    local latestSri="$(nix-hash --type sha256 --to-sri "$latestChecksum")"
    local localUrl="$(nix --extra-experimental-features nix-command eval --raw --file . androidStudioPackages."${channel}".unwrapped.src.drvAttrs.url)"
    local localHash="$(nix --extra-experimental-features nix-command eval --raw --file . androidStudioPackages."${channel}".unwrapped.src.drvAttrs.outputHash)"
    sed -i "s~${localUrl}~${latestUrl}~g" "${DEFAULT_NIX}"
    sed -i "s~${localHash}~${latestSri}~g" "${DEFAULT_NIX}"

    # Match the formatting of default.nix: `version = "2021.3.1.14"; # "Android Studio Dolphin (2021.3.1) Beta 5"`
    local versionString="${latestVersion}\"; # \"${latestName}\""
    sed -i "s~${localVersion}.*~${versionString}~g" "${DEFAULT_NIX}"
    echo "updated ${channel} to ${latestVersion}"
    echo "url: ${latestUrl}"
}

if (( $# == 0 )); then
    for channel in "beta" "canary" "stable"; do
        updateChannel "$channel"
    done
else
    while (( "$#" )); do
        case "$1" in
            beta|canary|stable)
                updateChannel "$1" ;;
            *)
                echo "unknown channel: $1" && exit 1 ;;
        esac
        shift 1
    done
fi
