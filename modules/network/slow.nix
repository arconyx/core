{ config, lib, ... }:
{
  options.arcworks.network.slow = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether the host is on a slow connection";
    example = true;
  };

  config = lib.mkIf config.arcworks.network.slow {
    nix.settings.max-substitution-jobs = 2;
  };
}
