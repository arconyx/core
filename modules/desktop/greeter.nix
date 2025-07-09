{ config, lib, ... }:
{
  options.arcworks.desktop.greeter.sddm.enable = lib.mkEnableOption "SDDM";

  config.services.displayManager.sddm = lib.mkIf config.arcworks.desktop.greeter.sddm.enable {
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    sugarCandyNix = {
      enable = !config.arcworks.desktop.desktopEnvironment.plasma.enable;
      settings = {
        # Background = set in device files
        ScreenWidth = 1920;
        ScreenHeight = 1080;
        FormPosition = "center";
        HaveFormBackground = false;
        FullBlur = false;
        ForceHideCompletePassword = true;
      };
    };
  };
}
