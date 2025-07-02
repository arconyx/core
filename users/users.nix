{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.arcworks.users = lib.mkOption {
    description = "User configuration";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "configuration for user ${name}";

            description = lib.mkOption {
              description = "A pretty name for the user";
              type = lib.types.passwdEntry lib.types.str;
              default = name;
              example = "Starlight";
            };

            isAdmin = lib.mkEnableOption "wheel membership";
            hide = lib.mkEnableOption "hide user from greeters";

            canUseNix = lib.mkOption {
              description = "Allows the user to connect to the Nix daemon.";
              type = lib.types.bool;
              default = true;
              example = false;
            };

            # this is taken from nixpkgs users-groups.nix
            shell = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.either lib.types.shellPackage (lib.types.passwdEntry lib.types.path)
              );
              default = pkgs.shadow; # weird but nixpkgs uses it - guess it wraps bash somehow?
              defaultText = lib.literalExpression "pkgs.shadow";
              example = lib.literalExpression "pkgs.bashInteractive";
              description = ''
                The path to the user's shell. Can use shell derivations,
                like `pkgs.bashInteractive`. Don't
                forget to enable your shell in
                `programs` if necessary,
                like `programs.zsh.enable = true;`.
              '';
            };

            # from nixpkgs sshd.nix
            sshKeys = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
              description = ''
                A list of verbatim OpenSSH public keys that should be added to the
                user's authorized keys. The keys are added to a file that the SSH
                daemon reads in addition to the the user's authorized_keys file.
                Warning: If you are using `NixOps` then don't use this
                option since it will replace the key required for deployment via ssh.
              '';
              example = [
                "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
                "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
              ];
            };

            settings = lib.mkOption {
              description = "Additional settings merged with the set passed to users.users.${name}";
              type = lib.types.attrs;
              default = { };
              example = {
                uid = 1001;
              };
            };

          };
        }
      )
    );
  };
  config =
    let
      cfg = config.arcworks.users;
      allUsers = lib.filterAttrs (name: value: value.enable) cfg;
    in
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";

      home-manager.users = lib.mapAttrs (name: userCfg: {
        imports = [ ./../home ];
        home.username = name;
        home.homeDirectory = "/home/${name}";
      }) allUsers;

      # Wanted by home manager's xdg.portal.enabled
      environment.pathsToLink = [
        "/share/xdg-desktop-portal"
        "/share/applications"
      ];

      users.users = lib.mapAttrs (
        name: userCfg:
        lib.mkMerge [
          {
            enable = userCfg.enable;
            isNormalUser = true;
            description = userCfg.description;
            extraGroups =
              lib.optionals userCfg.isAdmin [ "wheel" ]
              ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ];
            shell = userCfg.shell;
            openssh.authorizedKeys.keys = userCfg.sshKeys;
          }
          userCfg.settings
        ]
      ) allUsers;

      # hide users in sddm
      services.displayManager.sddm.settings.Users.HideUsers = builtins.concatStringsSep "," (
        builtins.attrNames (lib.filterAttrs (n: v: v.hide) allUsers)
      );

      # Restrict allowed users to only normal uses, excluding service accounts. This reduces risk
      # in the case of vulnerabilities in the daemon.
      nix.settings.allowed-users = builtins.attrNames (lib.filterAttrs (n: v: v.canUseNix) allUsers);
    };
}
