{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland =
    let
      launchPrefix = "${pkgs.uwsm}/bin/uwsm app --";

      terminal = "${launchPrefix} ${pkgs.kitty}/bin/kitty";
      fileManager = "${launchPrefix} ${pkgs.nautilus}/bin/nautilus";

      rofi = "${launchPrefix} ${pkgs.rofi}/bin/rofi";
      rofiBluetooth = "${launchPrefix} ${pkgs.rofi-bluetooth}/bin/rofi-bluetooth";
      rofiPowerMenu = "${rofi} -show powermenu -modi powermenu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
      rofiSystemd = "${launchPrefix} ${pkgs.rofi-systemd}/bin/rofi-systemd";

      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      hyprshot = "${pkgs.hyprshot}/bin/hyprshot";
      loginctl = "${pkgs.systemd}/bin/loginctl";
    in
    {
      enable = config.arcworks.home.hypr.enable;
      settings = {
        monitor = [
          ",preferred,auto,auto"
          "desc:BOE 0x08D6, preferred, auto, 1"
        ];

        # exec-once is a list of commands to run at startup
        exec-once = lib.optionals osConfig.arcworks.desktop.wallet.kwallet.enable [
          "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init"
        ];

        general = {
          gaps_in = 5;
          gaps_out = "15, 0, 15, 15";
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];
          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master.new_status = "master";

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = false;
          };
          numlock_by_default = true;
        };

        gestures.workspace_swipe = false;

        # KEYBINDINGS
        # Define the main modifier (still needed here for the binds)
        "$mainMod" = "SUPER";

        # bind, bindel, bindl, bindm are lists of strings
        bind = [
          "$mainMod, Q, exec, ${terminal}"
          "$mainMod, E, exec, ${fileManager}"
          # ", XF86Calculator, exec, ${rofi} -show calc -modi calc -no-show-match -no-sort"

          "$mainMod, C, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, V, togglefloating,"
          "$mainMod, P, pseudo," # dwindle
          "$mainMod, J, togglesplit," # dwindle
          "$mainMod, F, fullscreen"

          # menu
          "$mainMod, Space, exec, ${rofi} -show drun -run-command '${launchPrefix} {cmd}'"
          "$mainMod, B, exec, ${rofiBluetooth}"
          "$mainMod ALT, Delete, exec, ${rofiSystemd}"
          "$mainMod, TAB, exec, ${rofi} -show window"

          # session control
          "$mainMod, L, exec, ${loginctl} lock-session"
          "$mainMod CTRL, L, exec, ${rofiPowerMenu}"

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Scratchpad
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e-1"
          "$mainMod, mouse_up, workspace, e+1"
          # Rotate through existing workspaces with ctrl + super + arrow key
          "$mainMod CTRL, right, workspace, e+1"
          "$mainMod CTRL, left, workspace, e-1"

          # screenshots
          ", Print, exec, ${hyprshot} -m region --clipboard-only --freeze"
          "$mainMod, Print, exec, ${hyprshot} --mode window --output-folder ~/Pictures/Screenshots --freeze"
          "$mainMod CTRL, Print, exec, ${hyprshot} --mode output --output-folder ~/Pictures/Screenshots --freeze"
        ];

        bindel = [
          # Laptop multimedia keys for volume and LCD brightness
          ",XF86AudioRaiseVolume, exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, ${brightnessctl} s 10%+"
          ",XF86MonBrightnessDown, exec, ${brightnessctl} s 10%-"
        ];

        bindl = [
          # Requires playerctl
          ", XF86AudioNext, exec, ${playerctl} next"
          ", XF86AudioPause, exec, ${playerctl} play-pause"
          ", XF86AudioPlay, exec, ${playerctl} play-pause"
          ", XF86AudioPrev, exec, ${playerctl} previous"
        ];

        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        # WINDOWS AND WORKSPACES
        # windowrulev2 and workspace rules are lists of strings
        windowrulev2 = [
          # Ignore maximize requests from apps. You'll probably like this.
          "suppressevent maximize, class:.*"

          # Fix some dragging issues with XWayland
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          # force some windows to specify workspaces at launch
          "workspace 10, initialClass:spotify"
          "workspace 9, initialClass:discord"
          "workspace 1, initialClass:firefox" # untested

          # rofi on every screen
          "pin, initialClass:Rofi"
          "stayfocused, initialClass:Rofi"

          # Example windowrule v1 (uncomment to use)
          # "float, ^(kitty)$" # Use class regex

          # Example windowrule v2 (uncomment to use)
          # "float,class:^(kitty)$,title:^(kitty)$"

          # "Smart gaps" / "No gaps when only" (uncomment all if you wish to use that)
          # "bordersize 0, floating:0, onworkspace:w[tv1]"
          # "rounding 0, floating:0, onworkspace:w[tv1]"
          # "bordersize 0, floating:0, onworkspace:f[1]"
          # "rounding 0, floating:0, onworkspace:f[1]"
        ];

        workspace = [
          # Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
          # "Smart gaps" / "No gaps when only" (uncomment all if you wish to use that)
          # "w[tv1], gapsout:0, gapsin:0"
          # "f[1], gapsout:0, gapsin:0"
        ];
      };
    };
}
