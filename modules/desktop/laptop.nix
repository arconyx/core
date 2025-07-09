{ config, lib, ... }:
{
  options.arcworks.desktop.laptop.enable = lib.mkEnableOption "laptop specific options";

  config = lib.mkIf config.arcworks.desktop.laptop.enable {
    services.upower.enable = true;
    services.thermald.enable = true;
    services.tlp.enable = true;
  };
}
