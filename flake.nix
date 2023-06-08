{
  description = "jesse@jessemoore.dev NixOS configuration flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-serve-ng.url = "github:aristanetworks/nix-serve-ng";
    nix-config.url = "github:jesseDMoore1994/nix-config/packaging";
    nix-config.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, home-manager, nur, sops-nix, nixos-generators, nix-serve-ng, nix-config, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nix-config.lib;
      personalPackageSet = lib.systemPkgs {
        system = system;
        unfree = [
          "discord"
          "nvidia"
          "nvidia-x11"
          "nvidia-settings"
          "teams"
          "steam"
          "steam-original"
          "steam-run"
          "steam-runtime"
        ];
        overlays = [ nur.overlay ];
      };
      homeModules = nix-config.homeModules;
      systemModules = nix-config.systemModules;
      homeConfig = nix-config.homeModules;
      nixModule = systemModules.nix inputs;
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      homeManagerConfigurations = lib.createHomeManagerConfigs personalPackageSet {
        "jmoore@new_hostname" = {
          userConfig = homeConfig {
            pkgs = personalPackageSet;
            additionalModules = [ homeModules.xmonad ];
          };
          pkgs = personalPackageSet;
        };
      };
      nixosConfigurations = lib.createNixosSystems personalPackageSet {
        new_hostname = {
          hardwareConfig = {
            imports = [
              ./hardware-configs/new_hostname.nix
              nixModule
              systemModules.network
              systemModules.openssh
              systemModules.openvpn
              (systemModules.sops ./secrets/example.yaml)
              systemModules.sound
              systemModules.steam
              systemModules.tailscale
              systemModules.users
              systemModules.virtualization
              systemModules.xfce
              systemModules.xserver
            ];
          };
          system = personalPackageSet.system;
          pkgs = personalPackageSet;
        };
      };
    };
}
