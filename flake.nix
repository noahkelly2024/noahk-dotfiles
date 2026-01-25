{
  description = "noahk Home Manager flake for CachyOS (Hyprland + dotfiles)";

  inputs = {
    # Nixpkgs (pick a branch; unstable is common for Hyprland/Wayland tooling)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland plugins (for hyprscrolling in your home.nix)
    hyprland_plugins.url = "github:hyprwm/hyprland-plugins";
  };

  outputs = { self, nixpkgs, home-manager, hyprland_plugins, ... }@inputs:
    let
      # Change this if you’re on ARM: "aarch64-linux"
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        # Needed for google-chrome, discord, etc.
        config.allowUnfree = true;
      };
    in
    {
      # This is the config you'll apply with:
      # nix run home-manager/master -- switch --flake .#noahk
      homeConfigurations.noahk = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass flake inputs into your home.nix (so `inputs.self` works)
        extraSpecialArgs = { inherit inputs; };

        # Your Home Manager module
        modules = [
          ./home.nix

          # A couple of sane defaults that avoid common first-run footguns
          ({ config, ... }: {
            home.stateVersion = "25.05";
          })
        ];
      };
    };
}
