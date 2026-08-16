{
  description = "Hyprland on Nixos";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
      };

  outputs = inputs@{ self, nixpkgs,  ... }: {
    nixosConfigurations.nix-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        #home-manager.nixosModules.home-manager
      ];
    };
  };
}
