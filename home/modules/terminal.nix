{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  cfg = config.arcworks.terminal;
in
{
  options.arcworks.terminal = {
    default = lib.mkOption {
      type = lib.types.enum [
        "ghostty"
        "kitty"
      ];
      example = "ghostty";
      description = "Default terminal emulator";
    };

    ghostty.enable = lib.mkEnableOption "kitty";
    kitty.enable = lib.mkEnableOption "kitty";
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (
        !osConfig.arcworks.desktop.enable
      ) "Graphical TTY enabled but desktop is not enabled";

      assertions = [
        {
          assertion = cfg.default == "ghostty" -> cfg.ghostty.enable;
          message = "Ghostty is default terminal but is not enabled";
        }
        {
          assertion = cfg.default == "kitty" -> cfg.kitty.enable;
          message = "Kitty is default terminal but is not enabled";
        }
      ];

      # This is a custom helper for things like hyprland shortcuts
      home.sessionVariables.DEFAULT_TERMINAL_CMD = builtins.getAttr cfg.default {
        ghostty = "${lib.getExe config.programs.ghostty.package} +new-window";
        kitty = lib.getExe config.programs.kitty.package;
      };
    }

    # kitty
    (lib.mkIf cfg.kitty.enable {
      home.shellAliases.ssk = "kitten ssh";
      programs.kitty = {
        enable = true;
        themeFile = "Monokai_Soda";
        settings = {
          # MB. Approx 200,000 lines.
          # See https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.scrollback_pager_history_size
          scrollback_pager_history_size = 20;
          notify_on_cmd_finish = "invisible";
        };
      };
    })

    # ghostty
    (lib.mkIf cfg.ghostty.enable {
      assertions = [
        {
          assertion = builtins.elem pkgs.julia-mono osConfig.fonts.packages;
          message = "Ghostty is set to use Julia Mono as the font but it isn't in `fonts.packages`";
        }
      ];
      programs.ghostty = {
        enable = true;
        settings = {
          # bytes
          scrollback-limit = 1024 * 1024 * 20; # 20 MB
          # enable multiple bell types to have more chance of getting one through hyprland
          bell-features = "system,attention";
          # send notifications when a command is finished in the background
          notify_on_cmd_finish = "unfocused";
          notify-on-command-finish-action = "notify";
          # soft cap on memory usage via systemd
          linux-cgroup-memory-limit = "28G";
          # styling
          theme = "Nightfox";
          font-family = "Julia Mono";
          font-style = "Medium";
          # https://ghostty.org/docs/linux/systemd#starting-ghostty-at-login
          quit-after-last-window-closed = true;
          quit-after-last-window-closed-delay = "5m";
          # https://ghostty.org/docs/help/terminfo#ssh
          shell-integration-features = "ssh-terminfo,ssh-env";
        };
        systemd.enable = true;
      };
    })
  ];
}
