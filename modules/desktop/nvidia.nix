{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.arcworks.desktop.nvidia;
in
{
  options.arcworks.desktop.nvidia = {
    enable = lib.mkEnableOption "nvidia support";
    open = lib.mkOption {
      description = ''
        Passed to hardware.nvidia.open.
              
        You must configure `hardware.nvidia.open` on NVIDIA driver versions >= 560.
        It is suggested to use the open source kernel modules on Turing or later GPUs (RTX series, GTX 16xx),
        and the closed source modules otherwise.
        -- Assertion message in hardware.nvidia
      '';
      type = lib.types.nullOr lib.types.bool;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.arcworks.desktop.enable;
        message = "arcworks.desktop.nvidia.enable requires arcworks.desktop.enable";
      }
    ];

    # Load nvidia driver for Xorg and Wayland
    # This transitively enables nvidia support via hardware.nvidia
    # TODO: Replace with a simple hardware.nvidia.enable
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = cfg.open;
    # not needed for hardware functionality but useful
    environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
    # gpu acceleration
    # Also requires changes in firefox `about:config`
    # https://github.com/elFarto/nvidia-vaapi-driver/#firefox
    # Running `nvidia-smi` while decoding a video should show a Firefox process with C in the Type column.
    hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];
    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia"; # Required for libva 2.20+, forces libva to load this driver.
      MOZ_DISABLE_RDD_SANDBOX = 1; # Disables the sandbox for the RDD process that the decoder runs in.
    };
  };
}
