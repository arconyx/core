{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.desktop.fileManager = {
    nautilus.enable = lib.mkEnableOption "nautilus";
  };

  config =
    let
      cfg = config.arcworks.desktop.fileManager;
    in
    lib.mkIf cfg.nautilus.enable {
      environment.systemPackages = [ pkgs.nautilus ];

      programs.nautilus-open-any-terminal = {
        enable = true;
        terminal = "kitty";
      };

      # part of getting nautilus to behave
      xdg.terminal-exec = {
        enable = true;
        package = pkgs.xdg-terminal-exec-mkhl;
        # TODO: Tie this into the terminal module
        settings = {
          Hyprland = [ "kitty.desktop" ];
          default = [ "kitty.desktop" ];
        };
      };

      # Needed by Nautilus for a lot of stuff
      services.gvfs.enable = true;

      # Nautilus doesn't like our cursor and screams a bit
      # It should be fixed once https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7749
      # makes it into a stable release.
    };
}
