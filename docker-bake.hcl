variable "REGISTRY" {
  default = "ghcr.io/OWNER"
}

# Kernel versions (discovered from distro repos)
variable "KERNEL_EL9" {
  default = ""
}

variable "KERNEL_UBUNTU2404" {
  default = ""
}

variable "KERNEL_UBUNTU2204" {
  default = ""
}

variable "KERNEL_FC39" {
  default = ""
}

variable "KERNEL_FC40" {
  default = ""
}

variable "KERNEL_FC41" {
  default = ""
}

variable "KERNEL_FC42" {
  default = ""
}

variable "KERNEL_FC43" {
  default = ""
}

variable "KERNEL_RAWHIDE" {
  default = ""
}

variable "KERNEL_LEAP156" {
  default = ""
}

variable "KERNEL_TUMBLEWEED" {
  default = ""
}

variable "KERNEL_DEBIAN12" {
  default = ""
}

variable "KERNEL_UBUNTU2004" {
  default = ""
}

variable "KERNEL_ALMA9" {
  default = ""
}

variable "KERNEL_KITTEN" {
  default = ""
}

# HPE repo commits (pinned via flake.lock)
variable "SHS_CASSINI_HEADERS_REV" {
  default = ""
}

variable "SHS_FIRMWARE_REV" {
  default = ""
}

variable "SS_SBL_REV" {
  default = ""
}

variable "SS_LINK_REV" {
  default = ""
}

variable "SHS_CXI_DRIVER_REV" {
  default = ""
}

variable "SHS_KFABRIC_REV" {
  default = ""
}

variable "SHS_KDREG2_REV" {
  default = ""
}

function "notequal" {
  params = [a, b]
  result = a != b
}

group "default" {
  targets = [
    "el9",
    "alma9",
    "kitten",
    "ubuntu2404",
    "ubuntu2204",
    "ubuntu2004",
    "debian12",
    "fc39",
    "fc40",
    "fc41",
    "fc42",
    "fc43",
    "rawhide",
    "leap156",
    "tumbleweed"
  ]
}

group "stable" {
  targets = ["el9", "alma9", "ubuntu2404", "ubuntu2204", "ubuntu2004", "debian12", "fc39"]
}

target "_common" {
  dockerfile = "dockerfiles/shs-all.Dockerfile"
  context    = "."
  args = {
    SHS_CASSINI_HEADERS_REV = SHS_CASSINI_HEADERS_REV
    SHS_FIRMWARE_REV        = SHS_FIRMWARE_REV
    SS_SBL_REV              = SS_SBL_REV
    SS_LINK_REV             = SS_LINK_REV
    SHS_CXI_DRIVER_REV      = SHS_CXI_DRIVER_REV
    SHS_KFABRIC_REV         = SHS_KFABRIC_REV
    SHS_KDREG2_REV          = SHS_KDREG2_REV
  }
}

target "el9" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "rockylinux:9"
    KERNEL_FULL_VERSION = KERNEL_EL9
  }
  tags = notequal(KERNEL_EL9, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_EL9}-el9",
    "${REGISTRY}/shs-kmod:latest-el9"
  ] : []
}

target "alma9" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "almalinux:9"
    KERNEL_FULL_VERSION = KERNEL_ALMA9
  }
  tags = notequal(KERNEL_ALMA9, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_ALMA9}-alma9",
    "${REGISTRY}/shs-kmod:latest-alma9"
  ] : []
}

target "kitten" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "almalinux:10-kitten"
    KERNEL_FULL_VERSION = KERNEL_KITTEN
  }
  tags = notequal(KERNEL_KITTEN, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_KITTEN}-kitten",
    "${REGISTRY}/shs-kmod:latest-kitten"
  ] : []
}

target "ubuntu2404" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "ubuntu:24.04"
    KERNEL_FULL_VERSION = KERNEL_UBUNTU2404
  }
  tags = notequal(KERNEL_UBUNTU2404, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_UBUNTU2404}-ubuntu2404",
    "${REGISTRY}/shs-kmod:latest-ubuntu2404"
  ] : []
}

target "ubuntu2204" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "ubuntu:22.04"
    KERNEL_FULL_VERSION = KERNEL_UBUNTU2204
  }
  tags = notequal(KERNEL_UBUNTU2204, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_UBUNTU2204}-ubuntu2204",
    "${REGISTRY}/shs-kmod:latest-ubuntu2204"
  ] : []
}

target "ubuntu2004" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "ubuntu:20.04"
    KERNEL_FULL_VERSION = KERNEL_UBUNTU2004
  }
  tags = notequal(KERNEL_UBUNTU2004, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_UBUNTU2004}-ubuntu2004",
    "${REGISTRY}/shs-kmod:latest-ubuntu2004"
  ] : []
}

target "fc39" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:39"
    KERNEL_FULL_VERSION = KERNEL_FC39
  }
  tags = notequal(KERNEL_FC39, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_FC39}-fc39",
    "${REGISTRY}/shs-kmod:latest-fc39"
  ] : []
}

target "fc40" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:40"
    KERNEL_FULL_VERSION = KERNEL_FC40
  }
  tags = notequal(KERNEL_FC40, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_FC40}-fc40",
    "${REGISTRY}/shs-kmod:latest-fc40"
  ] : []
}

target "fc41" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:41"
    KERNEL_FULL_VERSION = KERNEL_FC41
  }
  tags = notequal(KERNEL_FC41, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_FC41}-fc41",
    "${REGISTRY}/shs-kmod:latest-fc41"
  ] : []
}

target "fc42" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:42"
    KERNEL_FULL_VERSION = KERNEL_FC42
  }
  tags = notequal(KERNEL_FC42, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_FC42}-fc42",
    "${REGISTRY}/shs-kmod:latest-fc42"
  ] : []
}

target "fc43" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:43"
    KERNEL_FULL_VERSION = KERNEL_FC43
  }
  tags = notequal(KERNEL_FC43, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_FC43}-fc43",
    "${REGISTRY}/shs-kmod:latest-fc43"
  ] : []
}

target "rawhide" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "fedora:rawhide"
    KERNEL_FULL_VERSION = KERNEL_RAWHIDE
  }
  tags = notequal(KERNEL_RAWHIDE, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_RAWHIDE}-rawhide",
    "${REGISTRY}/shs-kmod:latest-rawhide"
  ] : []
}

target "leap156" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "opensuse/leap:15.6"
    KERNEL_FULL_VERSION = KERNEL_LEAP156
  }
  tags = notequal(KERNEL_LEAP156, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_LEAP156}-leap156",
    "${REGISTRY}/shs-kmod:latest-leap156"
  ] : []
}

target "tumbleweed" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "opensuse/tumbleweed"
    KERNEL_FULL_VERSION = KERNEL_TUMBLEWEED
  }
  tags = notequal(KERNEL_TUMBLEWEED, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_TUMBLEWEED}-tumbleweed",
    "${REGISTRY}/shs-kmod:latest-tumbleweed"
  ] : []
}

target "debian12" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE          = "debian:12"
    KERNEL_FULL_VERSION = KERNEL_DEBIAN12
  }
  tags = notequal(KERNEL_DEBIAN12, "") ? [
    "${REGISTRY}/shs-kmod:${KERNEL_DEBIAN12}-debian12",
    "${REGISTRY}/shs-kmod:latest-debian12"
  ] : []
}
