{ config, lib, ... }:
{
  config = lib.mkIf (!config.arcworks.server.pi) {
    boot.loader.systemd-boot = {
      enable = true;
      editor = false;
    };

    boot.loader.efi.canTouchEfiVariables = true;

    # Limit the number of generations to keep
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.grub.configurationLimit = 10;
  };

}
