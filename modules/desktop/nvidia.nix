{
  config,
  lib,
  pkgs,
  ...
}:
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
    cuda.enable = lib.mkEnableOption "CUDA enabled builds";
  };

  config =
    let
      cfg = config.arcworks.desktop.nvidia;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.arcworks.desktop.enable;
          message = "arcworks.desktop.nvidia.enable requires arcworks.desktop.enable";
        }
      ];

      nixpkgs.config.cudaSupport = cfg.cuda.enable;
      nix.settings = lib.mkIf cfg.cuda.enable {
        substituters = [
          "https://cache.nixos-cuda.org?priority=60"
        ];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      # Load nvidia driver for Xorg and Wayland
      # This transitively enables nvidia support via hardware.nvidia
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];
      hardware.nvidia.open = lib.mkIf (cfg.open != null) cfg.open;

      environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
      environment.variables = {
        # https://github.com/elFarto/nvidia-vaapi-driver/#firefox
        LIBVA_DRIVER_NAME = "nvidia"; # Required for libva 2.20+, forces libva to load this driver.
        MOZ_DISABLE_RDD_SANDBOX = 1; # Disables the sandbox for the RDD process that the decoder runs in.
      };
    };
}
