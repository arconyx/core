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

  # TODO: test and remove
  #   i18n.extraLocaleSettings = {
  #     LC_ADDRESS = "en_NZ.UTF-8";
  #     LC_IDENTIFICATION = "en_NZ.UTF-8";
  #     LC_MEASUREMENT = "en_NZ.UTF-8";
  #     LC_MONETARY = "en_NZ.UTF-8";
  #     LC_NAME = "en_NZ.UTF-8";
  #     LC_NUMERIC = "en_NZ.UTF-8";
  #     LC_PAPER = "en_NZ.UTF-8";
  #     LC_TELEPHONE = "en_NZ.UTF-8";
  #     LC_TIME = "en_NZ.UTF-8";
  #   };

  time.timeZone = "Pacific/Auckland";

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
