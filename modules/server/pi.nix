{ config, lib, ... }:
{
  config = lib.mkIf config.arcworks.server.pi {
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=10M
    '';

    services.postgresql = {
      enableTCPIP = false;
      enableJIT = false;
      checkConfig = true;
      settings = {
        # memory
        shared_buffers = "8MB";
        temp_buffers = "2MB";
        max_prepared_transactions = 0;
        work_mem = "1MB";
        hash_mem_multiplier = 1.0;
        maintenance_work_mem = "2MB";
        autovacuum_work_mem = -1;
        autovacuum_max_workers = 3;
        logical_decoding_work_mem = "8MB";
      };
    };

    systemd.services.tailscaled.environment.GOGC = lib.mkIf config.arcworks.network.tailnet.enable "10";
  };
}
