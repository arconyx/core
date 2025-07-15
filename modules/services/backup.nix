{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.services.backups = {
    global = {
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Which paths to backup, for all backup configurations.
        '';
        example = [
          "/var/lib/postgresql"
          "/home/user/backup"
        ];
      };

      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Which patterns to exclude from backup, for all backup configurations.
        '';
        example = [
          "/var/cache"
          "/home/*/.cache"
          ".git"
        ];
      };
    };
    backup = lib.mkOption {
      description = "Remote backups with restic";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              repository = lib.mkOption {
                description = "Repository to backup to.";
                type = lib.types.str;
                example = "s3:https://bucket-host.example.com/bucket-host";
              };

              passwordFile = lib.mkOption {
                type = lib.types.str;
                description = ''
                  Read the repository password from a file.
                '';
                example = "/etc/nixos/restic-password";
              };

              environmentFile = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  file containing the credentials to access the repository, in the
                  format of an EnvironmentFile as described by {manpage}`systemd.exec(5)`
                '';
              };

              statusWebhook = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Discord webhook used to report failed backups";
              };

              paths = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Which paths to backup for this remote.
                '';
                example = [
                  "/var/lib/postgresql"
                  "/home/user/backup"
                ];
              };

              exclude = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Which patterns to exclude from backup for this remote.
                '';
                example = [
                  "/var/cache"
                  "/home/*/.cache"
                  ".git"
                ];
              };

              notifySuccess = lib.mkOption {
                type = lib.types.bool;
                default = config.arcworks.desktop.enable;
                description = "Notify user on successful backup";
                example = true;
              };

              notifyFailure = lib.mkOption {
                type = lib.types.bool;
                default = config.arcworks.desktop.enable;
                description = "Notify user on failed backup";
                example = true;
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config =
    let
      globalCfg = config.arcworks.services.backups.global;
      backupCfgs = config.arcworks.services.backups.backup;
      isDesktop = config.arcworks.desktop.enable;
      isServer = config.arcworks.server.enable;
      forEachUser =
        f: map f (builtins.attrNames (lib.filterAttrs (name: value: value.enable) config.arcworks.users));
    in
    {
      assertions = lib.concatLists (
        lib.mapAttrsToList (name: cfg: [
          {
            assertion = !isServer || (cfg.statusWebhook != null);
            message = "arcworks.services.backups.${name}: Server backup requires statusWebhook to be set";
          }
        ]) backupCfgs
      );

      services.restic.backups = lib.mapAttrs (name: cfg: {
        # core repository config
        repository = cfg.repository;
        environmentFile = cfg.environmentFile;
        passwordFile = cfg.passwordFile;

        # sensible defaults
        # disabled so we don't accidentally somehow create repos, override as needed
        # initialize = true
        inhibitsSleep = true;

        # We could maybe use globbing but this is nice and clear
        paths = lib.lists.unique (
          [
            "/root"
            # Needed to ensure consistent UID/GUID mappings on restore
            # We could fix uids in the user config (and did before now), but this is more flexible at the risk of problems when moving data.
            # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
            "/var/lib/nixos"
            "/etc/group"
            "/etc/machine-id"
            "/etc/NetworkManager/system-connections"
            "/etc/passwd"
            "/etc/shadow"
            "/etc/subgid"
            "/home"
            "/srv"
          ]
          ++ globalCfg.paths
          ++ cfg.paths
        );

        # While we can enable include paths based on if modules are active
        # We want exclusions always active, so that disabling a module
        # doesn't cause the files to start getting backed up
        exclude = lib.lists.unique (
          [
            # TODO: Parameterise this a bit more, so e.g. family systems backup ~/Downloads
            # General
            "/nix/store" # should never be included, but we'll be safe and explicitly exclude it
            ".cache" # why would we ever want a cache dir?
            ".local/share/Trash" # Exclude trash for obvious reasons
            "/home/*/.icons" # Handled by home manager

            # Dev tools
            ".git" # this should be obtainable from the remote with minimal loss
            ".gradle" # Eww
            "/home/*/.java" # Eww. Mostly looks like generated font config stuff.
            "node_modules" # Let npm worry about this
            "/home/*/.m2" # maven local

            # Julia is annoying. We only want environments.
            "/home/*/.julia/*" # the trailing wildcard is important because if we exclude .julia/ itself, then the invert won't work
            "!/home/*/.julia/environments" # inverted with ! to cancel match

            # What is it with programs sticking their crap into ~ instead of following XDG?
            "/home/*/.nix-defexpr"
            "/home/*/.nix-profile"
            # Lix has a flag to follow XDG - we can remove this once arconyx/core#2 is closed and we've migrated
          ]
          ++ globalCfg.exclude
          ++ cfg.exclude
        );

        extraBackupArgs = [
          "--exclude-caches"
          "--skip-if-unchanged"
          "--verbose"
          "--no-scan"
        ];

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 3"
          "--keep-monthly 6"
          "--keep-yearly 3"
        ];

        timerConfig = {
          OnCalendar = "daily";
          Persistent = isDesktop;
          RandomizedDelaySec = "4hr";
        };
      }) backupCfgs;

      systemd.targets = lib.concatMapAttrs (name: cfg: {
        "restic-backups-${name}-success".enable = true;
        "restic-backups-${name}-failure".enable = true;
      }) backupCfgs;

      systemd.services = lib.concatMapAttrs (
        name: cfg:
        lib.mkMerge (
          [
            {
              "restic-backups-${name}" = {
                onSuccess = [ "restic-backups-${name}-success.target" ];
                onFailure = [ "restic-backups-${name}-failure.target" ];

                # reduce memory use on pi zeros
                environment.GOGC = lib.mkIf config.arcworks.server.pi "10";
              };

              "notify-backup-${name}-failed-server" = lib.mkIf (cfg.statusWebhook != null) {
                enable = true;
                description = "Notify on failed backup";
                wantedBy = [ "restic-backups-${name}-failure.target" ];
                serviceConfig = {
                  Type = "oneshot";
                };

                script = ''
                  ${pkgs.curl}/bin/curl -F username=${config.networking.hostName} -F content="Backup failed" ${cfg.statusWebhook}
                '';
              };
            }
          ]
          ++ forEachUser (user: {
            "notify-backup-${name}-successful-desktop-${user}" = lib.mkIf cfg.notifySuccess {
              enable = true;
              description = "Notify user ${user} on successful backup";
              wantedBy = [ "restic-backups-${name}-success.target" ];
              serviceConfig = {
                Type = "oneshot";
                User = config.users.users.${user}.name;
              };

              script = ''
                DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${user})/bus" ${pkgs.libnotify}/bin/notify-send --urgency=low "Backup completed"
              '';
            };

            "notify-backup-${name}-failed-desktop-${user}" = lib.mkIf cfg.notifyFailure {
              enable = true;
              description = "Notify user ${user} on failed backup";
              wantedBy = [ "restic-backups-${name}-failure.target" ];
              serviceConfig = {
                Type = "oneshot";
                User = config.users.users.${user}.name;
              };

              # required for notify-send
              environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
                builtins.toString config.users.users.${user}.uid
              }/bus";

              script = ''
                ${pkgs.libnotify}/bin/notify-send --urgency=critical "Backup failed"
              '';
            };
          })
        )
      ) backupCfgs;
    };
}
