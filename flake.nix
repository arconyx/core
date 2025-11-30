{
  description = "NixOS logic ";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      ...
    }:
    let
      # We really shouldn't use special args for this
      # We could just calculate it from inputs.self or pass a module option up to here,
      # maybe as a nixosSystem wrapper.
      revision = self.shortRev or self.dirtyShortRev or self.lastModified or "unknown";

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      baseModules = [
        home-manager.nixosModules.home-manager
      ];
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

      nixosModules.default =
        { ... }:
        {
          imports = baseModules ++ [ ./core.nix ];
        };

      packages.x86_64-linux.default = self.nixosConfigurations.live.config.system.build.isoImage;

      nixosConfigurations.live = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit revision; };
        modules = baseModules ++ [ ./hosts/live ];
      };
    };
}
