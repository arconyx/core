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

              uptimeWebhook = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Webhook used to report successful backups, such as used by healthchecks.io or Uptime Kuma.";
              };

              statusEnvFile = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Environment file containing Discord and uptime webhooks as `WEBHOOK_URL` and `UPTIME_WEBHOOK`";
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

              prune = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable repository pruning. This locks the repository while running.";
                example = false;
              };

              check = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable repository checking. This locks the repository while running.";
                example = false;
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
            assertion = isServer -> (cfg.statusWebhook != null || cfg.statusEnvFile != null);
            message = "arcworks.services.backups.${name}: Server backup requires statusWebhook to be set";
          }
          {
            assertion = (cfg.statusWebhook != null) -> (cfg.statusEnvFile == null);
            message = "arcworks.services.backups.${name}: Only one of statusEnvFile and statusWebhook may be set.";
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
            # Note that inverted matches require wildcard matching the parent.
            # If we exclude `/folder/` then `!/folder/file` will have no effect.
            # But if we exclude `/folder/*/` then `!/folder/file` will work

            # General
            "/nix/store" # should never be included, but we'll be safe and explicitly exclude it
            ".cache" # why would we ever want a cache dir?
            ".local/share/Trash" # Exclude trash for obvious reasons
            "/home/*/.icons" # Handled by home manager
            "/home/*/.local/share/icons"
            "kitty-ssh-kitten"
            # annoying electron caches
            "/home/*/.config/*/*Cache*"
            "/home/*/.config/*/*cache*"
            "baloo" # plasma file index
            "__pycache__"

            # These ones could conceivably bite us in the ass in e.g.
            # source code trees but it's probably fine
            "Cache"
            "cache"
            "logs"
            "Logs"

            # Dev tools
            ".git" # this should be obtainable from the remote with minimal loss
            ".gradle" # Eww
            "/home/*/.java" # Eww. Mostly looks like generated font config stuff.
            "node_modules" # Let npm worry about this
            "/home/*/.m2" # maven local
            "/home/*/.config/direnv"
            ".direnv"
            # We want Julia environments but we don't care about the rest
            "/home/*/.julia/*"
            "!/home/*/.julia/environments"
            "/home/*/.npm"
            "/home/*/.nv"
            "/home/*/.pgadmin"
            "/home/*/.local/share/pnpm"
            "/home/*/.local/share/uv"
            # https://go.dev/wiki/GOPATH
            "/home/*/go"
            # just seems to have telemetry config
            ".config/go"

            # vscode and codium
            # keep the extensions manifest but not the code
            "/home/*/.vscode/extensions/"
            "/home/*/.vscode-oss/extensions/"
            "!/home/*/.vscode/extensions/extensions.json"
            "!/home/*/.vscode-oss/extensions/extensions.json"
            # backup user settings but dump the rest
            # it's mostly electron junk anyway
            # plus some workspace state, which we can afford to lose
            "/home/*/.config/Code/*"
            "/home/*/.config/VSCodium/*"
            "!/home/*/.config/Code/User/settings.json"
            "!/home/*/.config/VSCodium/User/settings.json"

            # What is it with programs sticking their crap into ~ instead of following XDG?
            "/home/*/.nix-defexpr"
            "/home/*/.nix-profile"
            # Lix has a flag to follow XDG - we can remove this once arconyx/core#2 is closed and we've migrated

            # firefox
            ".mozilla/firefox/Crash Reports"
            ".mozilla/firefox/*/datareporting/"
            # Stores data for websites, which we shouldn't trust to be durable
            "/home/*/.mozilla/firefox/*/storage"

            # Games
            "lutris/runners"
            "lutris/runtime"
            # I have a few of these from godot
            # Steam also has `shadercache` but that's handled under the next exclude
            "shader_cache"
            # Can just reinstall from Steam
            "/home/*/.local/share/Steam"

          ]
          ++ globalCfg.exclude
          ++ cfg.exclude
        );

        extraBackupArgs = [
          "--exclude-caches"
          "--skip-if-unchanged"
          "--verbose"
          "--no-scan"
          "--exclude-if-present .nobackup"
          # "--exclude-larger-than 1G"
        ];

        checkOpts = lib.optionals cfg.check [
          "--with-cache"
          "--read-data-subset=1%"
        ];

        pruneOpts = lib.optionals cfg.prune [
          "--keep-daily 7"
          "--keep-weekly 3"
          "--keep-monthly 6"
          "--keep-yearly 3"
          "--group-by host"
        ];

        timerConfig = {
          OnCalendar = "daily";
          Persistent = isDesktop;
          RandomizedDelaySec = "4hr";
        };
      }) backupCfgs;

      systemd.services = lib.concatMapAttrs (
        name: cfg:
        let
          statusWebookEnabled = (cfg.statusWebhook != null) || (cfg.statusEnvFile != null);
          uptimeWebookEnabled = (cfg.uptimeWebhook != null) || (cfg.statusEnvFile != null);
        in
        lib.mkMerge (
          [
            {
              "restic-backups-${name}" = {
                # TODO: See if disabling this has actually broken anything
                # reduce memory use on pi zeros
                # environment.GOGC = lib.mkIf config.arcworks.server.pi "10";

                onFailure = lib.optional statusWebookEnabled "notify-backup-${name}-failed-server.service";
                onSuccess = lib.optional uptimeWebookEnabled "notify-backup-${name}-success-server.service";
              };

              "notify-backup-${name}-failed-server" = lib.mkIf statusWebookEnabled {
                enable = true;
                description = "Notify on failed backup";
                serviceConfig = {
                  Type = "oneshot";
                  EnvironmentFile = lib.mkIf (cfg.statusEnvFile != null) cfg.statusEnvFile;
                };
                script =
                  let
                    webhookUrl = if cfg.statusWebhook != null then cfg.statusWebhook else "$WEBHOOK_URL";
                  in
                  ''
                    ${pkgs.curl}/bin/curl --silent -F username=${config.networking.hostName} -F content="Backup failed" "${webhookUrl}"
                  '';
              };

              "notify-backup-${name}-success-server" = lib.mkIf uptimeWebookEnabled {
                enable = true;
                description = "Ping uptime monitor with successful backup";
                serviceConfig = {
                  Type = "oneshot";
                  EnvironmentFile = lib.mkIf (cfg.statusEnvFile != null) cfg.statusEnvFile;
                };
                script =
                  let
                    webhookUrl = if cfg.uptimeWebhook != null then cfg.uptimeWebhook else "$UPTIME_URL";
                  in
                  ''
                    ${pkgs.curl}/bin/curl --silent "${webhookUrl}"
                  '';
              };
            }
          ]
          ++ forEachUser (user: {
            "restic-backups-${name}" = {
              onSuccess = lib.optional cfg.notifySuccess "notify-backup-${name}-successful-desktop-${user}.service";
              onFailure = lib.optional cfg.notifyFailure "notify-backup-${name}-failed-desktop-${user}.service";
            };

            # TODO: Have a single script that loops over users?
            "notify-backup-${name}-successful-desktop-${user}" = lib.mkIf cfg.notifySuccess {
              enable = true;
              description = "Notify user ${user} on successful backup";
              serviceConfig = {
                Type = "oneshot";
                User = config.users.users.${user}.name;
              };

              script = ''
                if users | ${pkgs.ripgrep}/bin/rg --quiet ${user}; then
                  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${user})/bus" ${pkgs.libnotify}/bin/notify-send --urgency=low "Backup completed"
                fi
              '';
            };

            "notify-backup-${name}-failed-desktop-${user}" = lib.mkIf cfg.notifyFailure {
              enable = true;
              description = "Notify user ${user} on failed backup";
              serviceConfig = {
                Type = "oneshot";
                User = config.users.users.${user}.name;
              };

              script = ''
                if users | ${pkgs.ripgrep}/bin/rg --quiet ${user}; then
                  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${user})/bus" ${pkgs.libnotify}/bin/notify-send --urgency=critical "Backup failed"
                fi
              '';
            };
          })
        )
      ) backupCfgs;
    };
}
