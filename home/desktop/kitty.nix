{ lib, osConfig, ... }:
{
  config = lib.mkIf osConfig.arcworks.desktop.enable {
    home.sessionVariables.TERMINAL = "kitty";
    home.shellAliases.ssk = "kitten ssh";

    programs.kitty = {
      enable = true;
      themeFile = "Monokai_Soda";
      settings = {
        "scrollback_pager_history_size" = 20; # MB. Approx 200,000 lines. See https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.scrollback_pager_history_size
      };
    };
  };
}
