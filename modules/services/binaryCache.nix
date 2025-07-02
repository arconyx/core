{
  config,
  lib,
  ...
}:
{
  options.arcworks.services.binaryCache = {
    enable = lib.mkEnableOption "hosting a binary cache";
    bindAddress = lib.mkOption {
      description = "IP address for this device";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    publicAddress = lib.mkOption {
      description = "Public address of binary cache";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    publicKey = lib.mkOption {
      description = "Public key of binary cache";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config =
    let
      cfg = config.arcworks.services.binaryCache;
    in
    {
      assertions = [
        {
          assertion = cfg.enable == (cfg.bindAddress != null);
          message = "arcworks.services.binaryCache: bindAddress must be set if binary cache is enabled";
        }
        {
          assertion = (cfg.publicAddress != null) == (cfg.publicKey != null);
          message = "arcworks.services.binaryCache: publicAddress and publicKey must both be set if one is";
        }
      ];
      services.nix-serve = lib.mkIf cfg.enable {
        enable = true;
        bindAddress = cfg.bindAddress;
        # WARNING: This will get blown away on reinstall!
        secretKeyFile = "/etc/nixstore/cache-priv-key.pem";
      };
      arcworks.services.backup.backblaze.paths = lib.optionals cfg.enable [ "/etc/nixstore" ];

      # enable using cache on devices that aren't hosting
      nix.settings =
        lib.mkIf
          (
            !cfg.enable
            && config.arcworks.network.tailnet.enable
            && (cfg.publicAddress != null)
            && (cfg.publicKey != null)
          )
          {
            substituters = lib.mkAfter [ "http://${cfg.publicAddress}:5000" ];
            trusted-public-keys = [
              "${cfg.publicAddress}:${cfg.publicKey}"
            ];
          };
    };
}
