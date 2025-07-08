{ config, lib, ... }:
{
  options.arcworks.desktop.laptop.enable = lib.mkEnableOption "laptop specific options";

  config = {
    services.upower.enable = config.arcworks.desktop.laptop.enable;
    services.thermald.enable = true;
    services.tlp.enable = true;
  };
}
