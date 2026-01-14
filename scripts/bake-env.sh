#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLAKE_LOCK="$REPO_ROOT/flake.lock"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

get_kernel() {
    "$SCRIPT_DIR/list-kernels.sh" "$1" latest 2>/dev/null || echo ""
}

get_commit() {
    jq -r ".nodes[\"$1\"].locked.rev // empty" "$FLAKE_LOCK"
}

declare -A DISTROS=(
    [KERNEL_EL9]="rockylinux:9"
    [KERNEL_ALMA9]="almalinux:9"
    [KERNEL_KITTEN]="almalinux:10-kitten"
    [KERNEL_UBUNTU2404]="ubuntu:24.04"
    [KERNEL_UBUNTU2204]="ubuntu:22.04"
    [KERNEL_UBUNTU2004]="ubuntu:20.04"
    [KERNEL_FC39]="fedora:39"
    [KERNEL_FC40]="fedora:40"
    [KERNEL_FC41]="fedora:41"
    [KERNEL_FC42]="fedora:42"
    [KERNEL_FC43]="fedora:43"
    [KERNEL_RAWHIDE]="fedora:rawhide"
    [KERNEL_LEAP156]="opensuse/leap:15.6"
    [KERNEL_TUMBLEWEED]="opensuse/tumbleweed"
    [KERNEL_DEBIAN12]="debian:12"
)

for var in "${!DISTROS[@]}"; do
    (get_kernel "${DISTROS[$var]}" > "$TMPDIR/$var") &
done

wait

for var in KERNEL_EL9 KERNEL_ALMA9 KERNEL_KITTEN KERNEL_UBUNTU2404 KERNEL_UBUNTU2204 \
           KERNEL_UBUNTU2004 KERNEL_FC39 KERNEL_FC40 KERNEL_FC41 KERNEL_FC42 KERNEL_FC43 \
           KERNEL_RAWHIDE KERNEL_LEAP156 KERNEL_TUMBLEWEED KERNEL_DEBIAN12; do
    echo "$var=$(cat "$TMPDIR/$var" 2>/dev/null || echo "")"
done

echo "SHS_CASSINI_HEADERS_REV=$(get_commit shs-cassini-headers)"
echo "SHS_FIRMWARE_REV=$(get_commit shs-firmware-cassini2-devel)"
echo "SS_SBL_REV=$(get_commit ss-sbl)"
echo "SS_LINK_REV=$(get_commit ss-link)"
echo "SHS_CXI_DRIVER_REV=$(get_commit shs-cxi-driver)"
echo "SHS_KFABRIC_REV=$(get_commit shs-kfabric)"
echo "SHS_KDREG2_REV=$(get_commit shs-kdreg2)"
