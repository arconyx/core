{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./modules
    ./users

    ./nix.nix
  ];

  options.arcworks = {
    revision = lib.mkOption {
      type = lib.types.str;
      description = ''
        Commit hash or equivalent description of source version.
        Should be full length and not a truncated form.
      '';
      example = lib.literalExpression "self.rev";
    };
  };

  config = {
    boot.tmp.cleanOnBoot = true;

    # Select internationalisation properties.
    i18n.defaultLocale = "en_NZ.UTF-8";
    time.timeZone = "Pacific/Auckland";

    # Link Local Name Resolution for LAN DNS
    # (reach LAN devices by hostname)
    # Having this true is a (small) security risk and we don't need it
    services.resolved.settings.Resolve.LLMNR = false;

    programs = {
      fish.enable = true;
      bat.enable = true;

      git = {
        enable = true;
        # config overriden by home manager
        config = {
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
          pull.ff = "only";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      # curl, gzip, xz included by nixos defaults

      # utils
      which
      htop
      ripgrep # recursively searches directories for a regex pattern
      eza # A modern replacement for ‘ls’
      bat # cat clone, but better
      fd # file search

      # editor
      helix
    ];

    # TODO: modularise helix at system level
    environment.sessionVariables.EDITOR = "hx";

    # Label versions
    system.configurationRevision = config.arcworks.revision;
    system.nixos.label =
      let
        rev = config.system.configurationRevision;
        trimmed = builtins.substring 0 8 rev;
        shortRev = if lib.hasSuffix "dirty" then "${trimmed}-dirty" else trimmed;
      in
      lib.maybeEnv "NIXOS_LABEL" (
        builtins.concatStringsSep "-" (
          (builtins.sort (x: y: x < y) config.system.nixos.tags)
          ++ [
            (lib.maybeEnv "NIXOS_LABEL_VERSION" config.system.nixos.version)
            "SHA:${shortRev}"
          ]
        )
      );

    systemd.enableStrictShellChecks = true;
  };
}
