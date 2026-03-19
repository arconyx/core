# Configuration for desktop environment
# Not applied in headless environment
{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf osConfig.arcworks.desktop.enable {
    programs.firefox.enable = true;

  };
}
