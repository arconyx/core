{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.services.backup = lib.mkOption {
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

            desktop = lib.mkOption {
              description = "Enable desktop backup defaults";
              type = lib.types.bool;
              default = config.arcworks.desktop.enable;
              example = true;
            };
            server = lib.mkOption {
              description = "Enable server backup defaults";
              type = lib.types.bool;
              default = config.arcworks.server.enable;
              example = true;
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
                Which paths to backup, in addition to the defaults from the server and/or desktop configurations.
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
                Which patterns to exclude from backup, in addition to the defaults from the server and/or desktop configurations.
              '';
              example = [
                "/var/cache"
                "/home/*/.cache"
                ".git"
              ];
            };
          };
        }
      )
    );
  };

  config =
    let
      backupCfgs = config.arcworks.services.backup;
    in
    {
      assertions = lib.concatLists (
        lib.mapAttrsToList (name: cfg: [
          {
            assertion = !cfg.server || (cfg.statusWebhook != null);
            message = "arcworks.services.backups.${name}: Server backup requires statusWebhook to be set";
          }
          {
            assertion = cfg.server || cfg.desktop;
            message = "arcworks.services.backups.${name}: At least one of server or desktop must be enabled";
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
            "/etc/subgid"
          ]
          ++ lib.optionals cfg.desktop [
            "/home/*/.ssh"
            "/home/*/Documents"
            "/home/*/Music"
            "/home/*/Pictures"
            "/home/*/Public"
            "/home/*/Videos"
            "/home/*/.mozilla/firefox"
          ]
          ++ lib.optionals cfg.server [
            "/home"
            "/srv"
          ]
          ++ cfg.paths
        );

        exclude = lib.lists.unique (
          [
            ".cache"
            ".git"
          ]
          ++ lib.optionals cfg.desktop [
            "/home/*/.mozilla/firefox/*/storage"
          ]
          ++ lib.optionals cfg.server [
            ".config/"
            ".local/"
          ]
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
          Persistent = config.arcworks.desktop.enable;
          RandomizedDelaySec = "4hr";
        };
      }) backupCfgs;

      systemd.services = lib.concatMapAttrs (name: cfg: {
        "restic-backups-${name}" = {
          onSuccess = lib.optionals cfg.desktop [ "notify-backup-successful-${name}-desktop.service" ];
          onFailure =
            lib.optionals cfg.desktop [ "notify-backup-failed-${name}-desktop.service" ]
            ++ lib.optionals cfg.server [ "notify-backup-failed-${name}-server.service" ];

          # reduce memory use on pi zeros
          environment.GOGC = lib.mkIf config.arcworks.server.pi "10";
        };

        "notify-backup-successful-${name}-desktop" = lib.mkIf cfg.desktop {
          enable = true;
          description = "Notify on successful backup";
          serviceConfig = {
            Type = "oneshot";
            User = config.users.users.arc.name;
          };

          # required for notify-send
          environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${builtins.toString config.users.users.arc.uid}/bus";

          script = ''
            ${pkgs.libnotify}/bin/notify-send --urgency=low "Backup completed"
          '';
        };

        "notify-backup-failed-${name}-desktop" = lib.mkIf cfg.desktop {
          enable = true;
          description = "Notify on failed backup";
          serviceConfig = {
            Type = "oneshot";
            User = config.users.users.arc.name;
          };

          # required for notify-send
          environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${builtins.toString config.users.users.arc.uid}/bus";

          script = ''
            ${pkgs.libnotify}/bin/notify-send --urgency=critical "Backup failed"
          '';
        };

        "notify-backup-failed-${name}-server" = lib.mkIf cfg.server {
          enable = true;
          description = "Notify on failed backup";
          serviceConfig = {
            Type = "oneshot";
          };

          script = ''
            ${pkgs.curl}/bin/curl -F username=${config.networking.hostName} -F content="Backup failed" ${cfg.statusWebhook}
          '';
        };
      }) backupCfgs;
    };
}
