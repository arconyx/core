{
  config,
  lib,
  ...
}:
let
  cfg = config.arcworks.systemd-boot;
in
{
  options.arcworks.systemd-boot.enable = lib.mkEnableOption "true";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable -> !config.boot.loader.generic-extlinux-compatible.enable;
        message = "Can't use systemd boot with extlinux bootloader";
      }
    ];

    boot.loader.systemd-boot = {
      enable = true;
      editor = false;
    };

    boot.loader.efi.canTouchEfiVariables = true;
    # Limit the number of generations to keep
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
