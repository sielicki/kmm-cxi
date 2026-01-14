{
  description = "KMM (Kernel Module Management) for HPE Slingshot CXI drivers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    shs-cassini-headers = {
      url = "github:HewlettPackard/shs-cassini-headers";
      flake = false;
    };
    shs-firmware-cassini2-devel = {
      url = "github:HewlettPackard/shs-firmware-cassini2-devel";
      flake = false;
    };
    ss-sbl = {
      url = "github:HewlettPackard/ss-sbl";
      flake = false;
    };
    ss-link = {
      url = "github:HewlettPackard/ss-link";
      flake = false;
    };
    shs-cxi-driver = {
      url = "github:HewlettPackard/shs-cxi-driver";
      flake = false;
    };
    shs-kfabric = {
      url = "github:HewlettPackard/shs-kfabric";
      flake = false;
    };
    shs-kdreg2 = {
      url = "github:HewlettPackard/shs-kdreg2";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            kubectl
            kubernetes-helm
            kind
            kustomize
            kubeconform
            podman
            skopeo
            gnumake
            git
            jq
            yq-go
          ];
        };
      }
    );
}
