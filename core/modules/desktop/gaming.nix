{ config, lib, ... }:
{
  options.arcworks.desktop.gaming.enable = lib.mkEnableOption "gaming support";

  config.programs = lib.mkIf config.arcworks.desktop.gaming.enable {
    gamemode.enable = true;

    # not available through home manager
    steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
