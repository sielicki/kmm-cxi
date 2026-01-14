#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${1:-}"
FORMAT="${2:-plain}"

# Use podman if available, otherwise docker
if command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
else
    CONTAINER_CMD="docker"
fi

if [[ -z "$BASE_IMAGE" ]]; then
    echo "Usage: $0 <base-image> [format]" >&2
    echo "  format: plain (default), json, latest" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 rockylinux:9" >&2
    echo "  $0 ubuntu:24.04 latest" >&2
    echo "  $0 fedora:42 json" >&2
    exit 1
fi

get_rpm_kernels() {
    local image="$1"
    $CONTAINER_CMD run --rm "docker.io/${image}" \
        dnf list --available --quiet 'kernel-devel' 2>/dev/null | \
        grep -E '^kernel-devel\.' | \
        awk '{print $2}' | \
        sed 's/$/.x86_64/'
}

get_ubuntu_kernels() {
    local image="$1"
    $CONTAINER_CMD run --rm "docker.io/${image}" bash -c \
        'apt-get update -qq >/dev/null 2>&1 && apt-cache search "^linux-headers-[0-9]" 2>/dev/null' | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-generic' | \
        sort -V | uniq
}

get_debian_kernels() {
    local image="$1"
    $CONTAINER_CMD run --rm "docker.io/${image}" bash -c \
        'apt-get update -qq >/dev/null 2>&1 && apt-cache search "^linux-headers-[0-9]" 2>/dev/null' | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-amd64' | \
        sort -V | uniq
}

get_zypper_kernels() {
    local image="$1"
    # openSUSE uses kernel-default-devel; extract version and append -default suffix
    $CONTAINER_CMD run --rm "docker.io/${image}" \
        zypper --non-interactive search -s kernel-default-devel 2>/dev/null | \
        grep -E '^\s*\|.*kernel-default-devel' | \
        awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}' | \
        grep -v '^$' | \
        sed 's/\.[0-9]*$/-default/' | \
        sort -V | uniq
}

kernels=""

case "$BASE_IMAGE" in
    *ubuntu*)
        kernels=$(get_ubuntu_kernels "$BASE_IMAGE")
        ;;
    *debian*)
        kernels=$(get_debian_kernels "$BASE_IMAGE")
        ;;
    *opensuse*|*suse*)
        kernels=$(get_zypper_kernels "$BASE_IMAGE")
        ;;
    *fedora*|*rocky*|*alma*|*centos*)
        kernels=$(get_rpm_kernels "$BASE_IMAGE")
        ;;
    *)
        echo "Unknown distro type: $BASE_IMAGE" >&2
        exit 1
        ;;
esac

if [[ -z "$kernels" ]]; then
    echo "No kernels found for $BASE_IMAGE" >&2
    exit 1
fi

case "$FORMAT" in
    json)
        echo "$kernels" | jq -R -s -c 'split("\n") | map(select(length > 0))'
        ;;
    latest)
        echo "$kernels" | tail -1
        ;;
    *)
        echo "$kernels"
        ;;
esac
