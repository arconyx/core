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
        shortRev = if lib.hasSuffix "dirty" rev then "${trimmed}-dirty" else trimmed;
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

    services.postgresql.initdbArgs = [
      # use the builtin C.UTF-8 locale (not the libc version) which should be stable across versions
      # when the locale depends on libc or icu then version changes can invalidate indices
      # for some reason this warns... and still uses the invalid indices, which can lead to corruption
      # so we use a builtin provider and hopefully avoid the hassle
      "--encoding=UTF8"
      "--locale=C.UTF-8"
      "--locale-provider=builtin"
    ];

    nixpkgs.overlays = [
      (self: super: {
        cacert =
          let
            newVersion = "3.131.1";
          in
          super.cacert.overrideAttrs (
            final: prev:
            if (lib.versionOlder prev.version newVersion) then
              builtins.warn "Using cacert override" {
                version = "3.131.1";
                src = self.fetchurl {
                  urls =
                    let
                      # This file is effectively a public interface, see the homepage link
                      file = "lib/ckfw/builtins/certdata.txt";
                      tag = "NSS_${lib.replaceStrings [ "." ] [ "_" ] newVersion}_RTM";
                    in
                    [
                      # Prefer mercurial as the canonical source, while github is just a mirror
                      "https://hg-edge.mozilla.org/projects/nss/raw-file/${tag}/${file}"
                      "https://raw.githubusercontent.com/nss-dev/nss/refs/tags/${tag}/${file}"
                    ];
                  hash = "sha256-PsK00kDcEsdH6vRQBh24SvdXxIO72jAvninOtdcL5RA=";
                };
              }
            else
              builtins.warn "Outdated cacert override present but not used" { }
          );
      })
    ];
  };
}
