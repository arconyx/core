{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fileManager.nix
    ./gaming.nix
    ./greeter.nix
    ./hypr.nix
    ./laptop.nix
    ./nvidia.nix
    ./wallet.nix
  ];

  options.arcworks.desktop = {
    enable = lib.mkEnableOption "graphical desktop configuration";
    debug = lib.mkEnableOption "debug tools";
    dualBoot = lib.mkEnableOption "Windows dual boot";
  };

  config =
    let
      cfg = config.arcworks.desktop;
      desktopEnvironments = builtins.attrValues cfg.desktopEnvironment;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = (builtins.length desktopEnvironments) >= 1;
          message = "arcworks.desktop: At least one desktop environment must be defined if the desktop is enabled";
        }
        {
          assertion = builtins.any (x: x.enable == true) desktopEnvironments;
          message = "arcworks.desktop: At least one desktop environment must be enabled if the desktop is enabled";
        }
      ];

      # default desktop config
      arcworks.desktop = {
        desktopEnvironment.hypr.enable = true;
        fileManager.nautilus.enable = true;
        greeter.sddm.enable = true;
        wallet.kwallet.enable = true;
      };

      # Enable networking
      networking.networkmanager.enable = true;

      # debug tooling
      environment.systemPackages =
        with pkgs;
        lib.optionals cfg.debug [
          clinfo
          glxinfo
          wayland-utils
          vulkan-tools
        ];

      # enable graphics
      hardware.graphics.enable = true;

      fonts.packages = with pkgs; [
        font-awesome # offload to hyprland config?
        julia-mono
      ];

      # audio
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;
      };

      # dual boot stuff
      time.hardwareClockInLocalTime = cfg.dualBoot;

      # for taildrive
      services.davfs2.enable = config.arcworks.network.tailnet.enable;

      # generally useful to have
      # TODO: consider enabling on some servers
      services.fwupd.enable = true;

      programs = {
        nix-ld.enable = true;
      };
    };
}
