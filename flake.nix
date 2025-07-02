{
  description = "NixOS logic ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sddm-sugar-candy-nix = {
      url = "github:Zhaith-Izaliel/sddm-sugar-candy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      # home-manager,
      # lix-module,
      pre-commit-hooks,
      # sddm-sugar-candy-nix,
      ...
    }:
    let
      # revision = self.shortRev or self.dirtyShortRev or self.lastModified or "unknown";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      # baseModules = [
      #   lix-module.nixosModules.default
      #   sddm-sugar-candy-nix.nixosModules.default
      #   home-manager.nixosModules.home-manager
      # ];
    in
    {
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            deadnix = {
              enable = true;
              settings.noLambdaArg = true;
            };
            nixfmt-rfc-style.enable = true;
            ripsecrets.enable = true;
            shellcheck.enable = true;
          };
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

    };
}
