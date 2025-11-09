{ pkgs, config, ... }:
{
  # Use Lix
  nix.package = pkgs.lixPackageSets.stable.lix;
  nixpkgs.overlays = [
    (final: prev: {
      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;
    })
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # The most common scenario in which this is useful is when we have registered substitutes
    # in order to perform binary distribution from, say, a network repository.
    # If the repository is down, the realisation of the derivation will fail.
    # When this option is specified, Lix will build the derivation instead.
    # Thus, installation from binaries falls back on installation from source.
    # This option is not the default since it is generally not desirable for a transient failure
    # in obtaining the substitutes to lead to a full build from source (with the related consumption of resources).
    # - [Lix Docs](https://docs.lix.systems/manual/lix/stable/command-ref/opt-common.html)
    fallback = !config.arcworks.server.pi;
    trusted-users = [ "@wheel" ];

    # Flox for cuda
    # Which we might also get through nix community, but hey
    # > With extra-substituters, Nix always checks cache.nixos.org first, and only uses Flox’s cache for packages not found upstream.
    # - https://discourse.nixos.org/t/nix-flox-nvidia-opening-up-cuda-redistribution-on-nix/69189
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  # Perform garbage collection to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Generate documentation including all module options
  # Accessible with `man configuration.nix` or `nixos-help` (html)
  # Had rebuild time impacts
  # documentation.nixos.includeAllModules = true;
}
