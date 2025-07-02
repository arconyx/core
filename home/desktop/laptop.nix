{ osConfig, lib, ... }:
{

  config = lib.mkIf osConfig.arcworks.desktop.laptop.enable {
    services.poweralertd = {
      enable = true;
      # -s ignore events at startup
      # -S only use events coming from power supplies
      extraArgs = [
        "-s"
        "-S"
      ];
    };
  };
}
