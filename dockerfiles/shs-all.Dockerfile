# syntax=docker/dockerfile:1.7
# HPE Slingshot Host Software - All Kernel Modules
# Optimized multi-stage build with per-repo caching
#
# Modules built:
#   - cxi-sl.ko (Slingshot Link driver - Cassini 2)
#   - cxi-ss1.ko (Main CXI driver)
#   - cxi-eth.ko (CXI Ethernet driver)
#   - cxi-user.ko (CXI userspace interface)
#   - kfabric.ko (Kernel Fabric Interface)
#   - kfi_cxi.ko (KFI CXI provider)
#   - kdreg2.ko (Memory registration tracking for libfabric/MPI)
#
# Build args:
#   KERNEL_FULL_VERSION - Target kernel version
#   BASE_IMAGE - Base image (rockylinux:9, ubuntu:24.04, fedora:39, etc.)
#   SHS_*_REV / SS_*_REV - HPE repo commit hashes (pinned via flake.lock)

ARG BASE_IMAGE=rockylinux:9

# HPE repo commits (pinned via flake.lock for reproducibility)
ARG SHS_CASSINI_HEADERS_REV
ARG SHS_FIRMWARE_REV
ARG SS_SBL_REV
ARG SS_LINK_REV
ARG SHS_CXI_DRIVER_REV
ARG SHS_KFABRIC_REV
ARG SHS_KDREG2_REV

# Stage 1: Base build tools (cached per BASE_IMAGE only)
FROM docker.io/${BASE_IMAGE} AS base-tools

ARG BASE_IMAGE

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/zypp,sharing=locked \
    if echo "${BASE_IMAGE}" | grep -qE "ubuntu|debian"; then \
        export DEBIAN_FRONTEND=noninteractive && \
        apt-get update && apt-get install -y \
        git make gcc bc flex bison libelf-dev libssl-dev kmod; \
    elif echo "${BASE_IMAGE}" | grep -qE "opensuse|suse"; then \
        zypper --non-interactive install \
        git make gcc bc flex bison elfutils libelf-devel libopenssl-devel perl kmod; \
    elif echo "${BASE_IMAGE}" | grep -qE "fedora|coreos"; then \
        dnf install -y git make gcc \
        elfutils-libelf-devel bc flex bison perl openssl-devel; \
    elif echo "${BASE_IMAGE}" | grep -qE "rocky|alma|centos"; then \
        dnf install -y epel-release && \
        dnf install -y git make gcc \
        elfutils-libelf-devel bc flex bison perl; \
    fi

# Stage 2: Clone source repos (each ADD is cached independently by content)
FROM base-tools AS sources

ARG SHS_CASSINI_HEADERS_REV
ARG SHS_FIRMWARE_REV
ARG SS_SBL_REV
ARG SS_LINK_REV
ARG SHS_CXI_DRIVER_REV
ARG SHS_KFABRIC_REV
ARG SHS_KDREG2_REV

WORKDIR /build

# Each repo is pinned to a specific commit from flake.lock
ADD https://github.com/HewlettPackard/shs-cassini-headers.git#${SHS_CASSINI_HEADERS_REV} /build/shs-cassini-headers/
ADD https://github.com/HewlettPackard/shs-firmware-cassini2-devel.git#${SHS_FIRMWARE_REV} /build/shs-firmware-cassini2-devel/
ADD https://github.com/HewlettPackard/ss-sbl.git#${SS_SBL_REV} /build/ss-sbl/
ADD https://github.com/HewlettPackard/ss-link.git#${SS_LINK_REV} /build/ss-link/
ADD https://github.com/HewlettPackard/shs-cxi-driver.git#${SHS_CXI_DRIVER_REV} /build/shs-cxi-driver/
ADD https://github.com/HewlettPackard/shs-kfabric.git#${SHS_KFABRIC_REV} /build/shs-kfabric/
ADD https://github.com/HewlettPackard/shs-kdreg2.git#${SHS_KDREG2_REV} /build/shs-kdreg2/

# Set up header paths (doesn't depend on kernel version)
# Note: firmware repo provides headers (cuc_cxi.h) needed for build, not runtime firmware
RUN mkdir -p /build/cassini-headers/install && \
    cp -r /build/shs-cassini-headers/include /build/cassini-headers/install/ && \
    mkdir -p /build/firmware_cassini/lib && \
    cp -r /build/shs-firmware-cassini2-devel/lib/* /build/firmware_cassini/lib/

# Set up ss-sbl headers
RUN mkdir -p /build/ss-sbl/staging_dir/usr/include/linux && \
    cp -r /build/ss-sbl/uapi /build/ss-sbl/staging_dir/usr/include/ && \
    cp /build/ss-sbl/*.h /build/ss-sbl/staging_dir/usr/include/ 2>/dev/null || true && \
    cp /build/ss-sbl/*.h /build/ss-sbl/staging_dir/usr/include/linux/ 2>/dev/null || true && \
    touch /build/ss-sbl/Module.symvers

# Set up symlinks for cxi-driver
RUN mkdir -p /build/shs-cxi-driver/drivers/net/ethernet && \
    ln -sf /build/ss-link /build/shs-cxi-driver/drivers/net/ethernet/sl-driver && \
    ln -sf /build/ss-sbl /build/shs-cxi-driver/drivers/net/ethernet/slingshot_base_link && \
    ln -sf /build/ss-link /build/sl-driver && \
    ln -sf /build/ss-sbl /build/slingshot_base_link && \
    ln -sf /build/shs-cxi-driver /build/cxi-driver

# Stage 3: Build with kernel headers (varies by KERNEL_FULL_VERSION)
FROM sources AS builder

ARG KERNEL_FULL_VERSION
ARG BASE_IMAGE

ENV KDIR=/lib/modules/${KERNEL_FULL_VERSION}/build

# Install kernel-specific headers
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/zypp,sharing=locked \
    if echo "${BASE_IMAGE}" | grep -qE "ubuntu|debian"; then \
        export DEBIAN_FRONTEND=noninteractive && \
        apt-get update && apt-get install -y linux-headers-${KERNEL_FULL_VERSION}; \
    elif echo "${BASE_IMAGE}" | grep -qE "opensuse|suse"; then \
        zypper --non-interactive install kernel-default-devel && \
        ls -la /lib/modules/${KERNEL_FULL_VERSION}/build; \
    elif echo "${BASE_IMAGE}" | grep -qE "fedora|coreos"; then \
        dnf install -y kernel-devel-${KERNEL_FULL_VERSION} && \
        mkdir -p /lib/modules/${KERNEL_FULL_VERSION} && \
        ln -sf /usr/src/kernels/${KERNEL_FULL_VERSION} /lib/modules/${KERNEL_FULL_VERSION}/build; \
    elif echo "${BASE_IMAGE}" | grep -qE "rocky|alma|centos"; then \
        dnf install -y kernel-devel-${KERNEL_FULL_VERSION} kernel-headers-${KERNEL_FULL_VERSION} && \
        mkdir -p /lib/modules/${KERNEL_FULL_VERSION} && \
        ln -sf /usr/src/kernels/${KERNEL_FULL_VERSION} /lib/modules/${KERNEL_FULL_VERSION}/build; \
    fi

# Build ss-link (cxi-sl.ko)
WORKDIR /build/ss-link
RUN git init && git config user.email "build@local" && git config user.name "Build" && \
    git add -A && git commit -m "build" && \
    cp ./common/configs/config.mak.cassini ./config.mak && \
    make KDIR=/lib/modules/${KERNEL_FULL_VERSION}/build \
    KCFLAGS="-Wall -Werror"

# Build CXI driver (cxi-ss1.ko, cxi-eth.ko, cxi-user.ko)
WORKDIR /build/shs-cxi-driver
RUN make -C drivers/net/ethernet/hpe/ss1 \
    KDIR=/lib/modules/${KERNEL_FULL_VERSION}/build \
    TOPDIR=/build/shs-cxi-driver/drivers/net/ethernet/hpe \
    NO_BUILD_TESTS=1 \
    KBUILD_MODPOST_WARN=1 \
    KCFLAGS="-Wall -Werror"

# Build kfabric (kfabric.ko, kfi_cxi.ko)
WORKDIR /build/shs-kfabric
RUN make \
    KDIR=/lib/modules/${KERNEL_FULL_VERSION}/build \
    KBUILD_MODPOST_WARN=1 \
    KCFLAGS="-Wall -Werror"

# Build kdreg2 (kdreg2.ko) - VM monitoring for memory registration
WORKDIR /build/shs-kdreg2
RUN make \
    KDIR=/lib/modules/${KERNEL_FULL_VERSION}/build \
    KBUILD_MODPOST_WARN=1 \
    KCFLAGS="-Wall -Werror"

# Stage 4: Final minimal image
FROM docker.io/${BASE_IMAGE}

ARG KERNEL_FULL_VERSION
ARG BASE_IMAGE

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/zypp,sharing=locked \
    if echo "${BASE_IMAGE}" | grep -qE "ubuntu|debian"; then \
        apt-get update && apt-get install -y kmod; \
    elif echo "${BASE_IMAGE}" | grep -qE "opensuse|suse"; then \
        zypper --non-interactive install kmod; \
    elif echo "${BASE_IMAGE}" | grep -qE "fedora|coreos"; then \
        dnf install -y kmod; \
    elif echo "${BASE_IMAGE}" | grep -qE "rocky|alma|centos"; then \
        if command -v microdnf >/dev/null 2>&1; then \
            microdnf install -y kmod; \
        else \
            dnf install -y kmod; \
        fi; \
    fi

RUN mkdir -p /opt/lib/modules/${KERNEL_FULL_VERSION}

# Copy kernel modules
COPY --from=builder /build/ss-link/drivers/net/ethernet/hpe/sl/cxi-sl.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-cxi-driver/drivers/net/ethernet/hpe/ss1/cxi-ss1.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-cxi-driver/drivers/net/ethernet/hpe/ss1/cxi-eth.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-cxi-driver/drivers/net/ethernet/hpe/ss1/cxi-user.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-kfabric/kfi/kfabric.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-kfabric/prov/cxi/kfi_cxi.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/
COPY --from=builder /build/shs-kdreg2/kdreg2.ko \
    /opt/lib/modules/${KERNEL_FULL_VERSION}/

RUN depmod -b /opt ${KERNEL_FULL_VERSION}
