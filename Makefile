.PHONY: help install-kmm deploy deploy-dev undeploy bake bake-stable bake-push build list-kernels lint show-versions

REGISTRY ?= ghcr.io/OWNER
FLAKE_LOCK := flake.lock

# Extract HPE repo commits from flake.lock
SHS_CASSINI_HEADERS_REV := $(shell jq -r '.nodes["shs-cassini-headers"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SHS_FIRMWARE_REV := $(shell jq -r '.nodes["shs-firmware-cassini2-devel"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SS_SBL_REV := $(shell jq -r '.nodes["ss-sbl"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SS_LINK_REV := $(shell jq -r '.nodes["ss-link"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SHS_CXI_DRIVER_REV := $(shell jq -r '.nodes["shs-cxi-driver"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SHS_KFABRIC_REV := $(shell jq -r '.nodes["shs-kfabric"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)
SHS_KDREG2_REV := $(shell jq -r '.nodes["shs-kdreg2"].locked.rev // empty' $(FLAKE_LOCK) 2>/dev/null)

help:
	@echo "KMM CXI Driver - HPE Slingshot Host Software Kernel Modules"
	@echo ""
	@echo "Build (buildx bake - recommended):"
	@echo "  make bake              Build all distros in parallel"
	@echo "  make bake-push         Build and push all distros"
	@echo "  make bake TARGET=el9   Build single target"
	@echo "  make bake-stable       Build only known-working distros"
	@echo ""
	@echo "Targets: el9, alma9, kitten, ubuntu2404, ubuntu2204, ubuntu2004, debian12, fc39, fc40, fc41, fc42, fc43, rawhide, leap156, tumbleweed"
	@echo ""
	@echo "Build (single image):"
	@echo "  make build BASE_IMAGE=<image> KERNEL=<version>"
	@echo ""
	@echo "Utilities:"
	@echo "  make list-kernels BASE_IMAGE=<image>"
	@echo "  make show-versions     Show pinned HPE repo versions"
	@echo ""
	@echo "Deploy:"
	@echo "  make install-kmm                  Install KMM operator"
	@echo "  make deploy REGISTRY=ghcr.io/org  Deploy SHS modules (set your registry)"
	@echo "  make deploy-dev                   Deploy with localhost:5000 registry"
	@echo "  make undeploy                     Remove SHS modules"
	@echo ""
	@echo "Version Management:"
	@echo "  nix flake update       Update all dependencies including HPE repos"
	@echo ""
	@echo "Note: Fedora 40+ builds may fail due to kernel API changes (6.14+)"
	@echo "      They are included to automatically work when upstream is fixed"

show-versions:
	@echo "HPE Repository Versions (from flake.lock):"
	@echo "  shs-cassini-headers:        $(SHS_CASSINI_HEADERS_REV)"
	@echo "  shs-firmware-cassini2-devel: $(SHS_FIRMWARE_REV)"
	@echo "  ss-sbl:                     $(SS_SBL_REV)"
	@echo "  ss-link:                    $(SS_LINK_REV)"
	@echo "  shs-cxi-driver:             $(SHS_CXI_DRIVER_REV)"
	@echo "  shs-kfabric:                $(SHS_KFABRIC_REV)"
	@echo "  shs-kdreg2:                 $(SHS_KDREG2_REV)"

install-kmm:
	kubectl apply -k https://github.com/kubernetes-sigs/kernel-module-management/config/default

deploy:
ifeq ($(REGISTRY),ghcr.io/OWNER)
	$(error REGISTRY must be set. Example: make deploy REGISTRY=ghcr.io/myorg)
endif
ifeq ($(SHS_CASSINI_HEADERS_REV),)
	$(error flake.lock not found or missing HPE repo entries. Run 'nix flake update' first.)
endif
	@kustomize build manifests/base | \
		sed 's|ghcr.io/OWNER|$(REGISTRY)|g' | \
		sed 's|__SHS_CASSINI_HEADERS_REV__|$(SHS_CASSINI_HEADERS_REV)|g' | \
		sed 's|__SHS_FIRMWARE_REV__|$(SHS_FIRMWARE_REV)|g' | \
		sed 's|__SS_SBL_REV__|$(SS_SBL_REV)|g' | \
		sed 's|__SS_LINK_REV__|$(SS_LINK_REV)|g' | \
		sed 's|__SHS_CXI_DRIVER_REV__|$(SHS_CXI_DRIVER_REV)|g' | \
		sed 's|__SHS_KFABRIC_REV__|$(SHS_KFABRIC_REV)|g' | \
		kubectl apply -f -

deploy-dev:
ifeq ($(SHS_CASSINI_HEADERS_REV),)
	$(error flake.lock not found or missing HPE repo entries. Run 'nix flake update' first.)
endif
	@kustomize build manifests/overlays/dev | \
		sed 's|__SHS_CASSINI_HEADERS_REV__|$(SHS_CASSINI_HEADERS_REV)|g' | \
		sed 's|__SHS_FIRMWARE_REV__|$(SHS_FIRMWARE_REV)|g' | \
		sed 's|__SS_SBL_REV__|$(SS_SBL_REV)|g' | \
		sed 's|__SS_LINK_REV__|$(SS_LINK_REV)|g' | \
		sed 's|__SHS_CXI_DRIVER_REV__|$(SHS_CXI_DRIVER_REV)|g' | \
		sed 's|__SHS_KFABRIC_REV__|$(SHS_KFABRIC_REV)|g' | \
		kubectl apply -f -

undeploy:
	kustomize build manifests/base | kubectl delete -f - --ignore-not-found

bake:
	@eval $$(./scripts/bake-env.sh) && \
	docker buildx bake $(if $(TARGET),$(TARGET),) --print && \
	docker buildx bake $(if $(TARGET),$(TARGET),)

bake-stable:
	@eval $$(./scripts/bake-env.sh) && \
	docker buildx bake stable --print && \
	docker buildx bake stable

bake-push:
ifeq ($(REGISTRY),ghcr.io/OWNER)
	$(error REGISTRY must be set. Example: make bake-push REGISTRY=ghcr.io/myorg)
endif
	@eval $$(./scripts/bake-env.sh) && \
	REGISTRY=$(REGISTRY) docker buildx bake --push

build:
ifndef BASE_IMAGE
	$(error BASE_IMAGE is required. Example: make build BASE_IMAGE=fedora:39 KERNEL=6.11.9-100.fc39.x86_64)
endif
ifndef KERNEL
	$(error KERNEL is required. Run 'make list-kernels BASE_IMAGE=$(BASE_IMAGE)' to see available versions)
endif
ifeq ($(SHS_CASSINI_HEADERS_REV),)
	$(error flake.lock not found or missing HPE repo entries. Run 'nix flake update' first.)
endif
	@echo "Building SHS modules for $(BASE_IMAGE) kernel $(KERNEL)"
	@echo "Using HPE repo commits from flake.lock"
	docker buildx build \
		--build-arg KERNEL_FULL_VERSION=$(KERNEL) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg SHS_CASSINI_HEADERS_REV=$(SHS_CASSINI_HEADERS_REV) \
		--build-arg SHS_FIRMWARE_REV=$(SHS_FIRMWARE_REV) \
		--build-arg SS_SBL_REV=$(SS_SBL_REV) \
		--build-arg SS_LINK_REV=$(SS_LINK_REV) \
		--build-arg SHS_CXI_DRIVER_REV=$(SHS_CXI_DRIVER_REV) \
		--build-arg SHS_KFABRIC_REV=$(SHS_KFABRIC_REV) \
		-t $(REGISTRY)/shs-kmod:$(KERNEL) \
		-f dockerfiles/shs-all.Dockerfile \
		--load .

list-kernels:
ifndef BASE_IMAGE
	$(error BASE_IMAGE is required. Example: make list-kernels BASE_IMAGE=fedora:39)
endif
	@./scripts/list-kernels.sh $(BASE_IMAGE)

lint:
	kustomize build manifests/base > /dev/null
	kustomize build manifests/overlays/dev > /dev/null
	@echo "Manifests are valid"
