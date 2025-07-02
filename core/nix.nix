{ ... }:
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    # Enable the Flakes feature and the accompanying new nix command-line tool
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [ "@wheel" ];

    # Optimize storage
    # You can also manually optimize the store via:
    #    nix-store --optimise
    # Refer to the following link for more details:
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    auto-optimise-store = true;

  };

  # Perform garbage collection to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Generate documentation including all module options
  # Accessible with `man configuration.nix` or `nixos-help` (html)
  documentation.nixos.includeAllModules = true;
}
