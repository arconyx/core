# Imported for each user in core/users.nix
# Some options are only disabled on the pis, to keep them minimal

{
  osConfig,
  pkgs,
  ...
}:
{
  imports = [
    ./desktop
    ./hypr

    ./helix.nix
    ./julia.nix
    ./neovim.nix
  ];

  arcworks.neovim.enable = false;
  arcworks.helix.enable = true;

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    curlie
    dysk
  ];

  # Only for generic aliases compatible across shells
  home.shellAliases = {
    download = "curlie -sSfLO"; # download silently, but fail and print error if we get an http error
    # masking standard commands
    cat = "bat";
  };

  programs = {
    direnv.enable = true;
    fd.enable = true;
    home-manager.enable = true; # Let home Manager install and manage itself.

    # Avoid following error when running commands that don't exist:
    # DBI connect('dbname=/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite','',...) failed: unable to open database file at /run/current-system/sw/bin/command-not-found line 13.
    # cannot open database `/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite' at /run/current-system/sw/bin/command-not-found line 13.
    nix-index.enable = !osConfig.arcworks.server.pi;
    # TODO: Disable command not found support entirely on systems without nixindex

    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
      '';
      historyControl = [ "ignoreboth" ];
    };

    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batman
      ];
    };

    eza = {
      enable = true;
      icons = "auto";
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        fish_vi_key_bindings
        bind / fzf-history-widget
        batman --export-env | source
      '';
    };

    fzf = {
      enable = true;
      defaultCommand = "fd --type f --strip-cwd-prefix";
    };

    git = {
      enable = true;
      delta = {
        enable = true;
        options.navigate = true;
      };
      ignores = [
        ".direnv/"
        ".envrc"
      ];
      extraConfig = {
        safe.directory = "/config/*";
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        pull.ff = "only";
      };
    };

    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--follow"
      ];
    };

    ssh = {
      enable = true;
      addKeysToAgent = "yes";
      hashKnownHosts = true;
    };
  };

  xdg = {
    enable = true;
    userDirs.enable = true;
  };

  services.ssh-agent.enable = !osConfig.arcworks.server.pi;

  # TODO: Parameterise per system
  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
