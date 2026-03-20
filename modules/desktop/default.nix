{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.arcworks.desktop;
in
{
  imports = [
    ./fileManager.nix
    ./gaming.nix
    ./laptop.nix
    ./nvidia.nix
    ./wallet.nix
  ];

  options.arcworks.desktop = {
    enable = lib.mkEnableOption "graphical desktop configuration";
    debug = lib.mkEnableOption "debug tools";
    dualBoot = lib.mkEnableOption "Windows dual boot";
  };

  config = lib.mkIf cfg.enable {
    # default desktop config
    arcworks.desktop = {
      fileManager.nautilus.enable = true;
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
      appimage = {
        enable = true;
        binfmt = true;
      };
    };

    # TODO: Unstable has a change incoming that will automatically
    # refresh roots when direnv loads a directory
    services.angrr = {
      enable = true;
      enableNixGcIntegration = true;
      period = "2months";
      extraArgs = [
        "--ignore-directories-in-home"
        ".local/state/nix/profiles"
        "--ignore-directories-in-home"
        ".local/state/home-manager/gcroots"
      ];
    };

  };
}
