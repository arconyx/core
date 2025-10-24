{
  config,
  lib,
  pkgs,
  revision,
  ...
}:
{
  imports = [
    ./modules
    ./overlays
    ./users

    ./boot.nix
    ./nix.nix
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";

  time.timeZone = "Pacific/Auckland";

  # Link Local Name Resolution for LAN DNS
  # (reach LAN devices by hostname)
  # Having this true is a (small) security risk and we don't need it
  services.resolved.llmnr = "false";

  programs = {
    fish.enable = true;

    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batman
      ];
    };

    git = {
      enable = true;
      # config overriden by home manager
      config = {
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        pull.ff = "only";
      };
      package = if config.arcworks.server.minimal.enable then pkgs.gitMinimal else pkgs.git;
    };

    # default neovim config for editing as root
    # overriden by home manager
    neovim = {
      enable = false; # disabled in favour of helix
      defaultEditor = true;
      vimAlias = true;
      configure = {
        customRC = ''
            set number
          	set shiftwidth=4 smarttab
          	set tabstop=7 softtabstop=0
        '';
      };
    };

    nh = {
      enable = !config.arcworks.server.minimal.enable;
      flake = "/config";
    };
  };

  environment.systemPackages = with pkgs; [
    # archives
    zip
    xz
    unzip
    _7zz

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
  system.configurationRevision = revision;
  system.nixos.label = lib.maybeEnv "NIXOS_LABEL" (
    builtins.concatStringsSep "-" (
      (builtins.sort (x: y: x < y) config.system.nixos.tags)
      ++ [
        (lib.maybeEnv "NIXOS_LABEL_VERSION" config.system.nixos.version)
        "SHA:${revision}"
      ]
    )
  );

  systemd.enableStrictShellChecks = true;
}
