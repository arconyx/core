{ config, ... }:
{
  imports = [
    ./tailnet.nix
    ./slow.nix
  ];

  # Firewall is enabled by default but we'll be explicit
  networking.firewall.enable = true;
  services.resolved.enable = true;

  # caddy local ca root certificate
  security.pki.certificates = [
    ''
      -----BEGIN CERTIFICATE-----
      MIIBojCCAUmgAwIBAgIQLtQnx4Du9v98oKYUj/sHLTAKBggqhkjOPQQDAjAwMS4w
      LAYDVQQDEyVDYWRkeSBMb2NhbCBBdXRob3JpdHkgLSAyMDI0IEVDQyBSb290MB4X
      DTI0MDEwMzAzMTEwOVoXDTMzMTExMTAzMTEwOVowMDEuMCwGA1UEAxMlQ2FkZHkg
      TG9jYWwgQXV0aG9yaXR5IC0gMjAyNCBFQ0MgUm9vdDBZMBMGByqGSM49AgEGCCqG
      SM49AwEHA0IABCFFmoSbEGPk60CzIyZxdIKsNSUaWC2I9ghbA6OFMQ/u+aBP6CCb
      nPq76qKOvdYogvSk/6L5q5PKESfTKAk7AcCjRTBDMA4GA1UdDwEB/wQEAwIBBjAS
      BgNVHRMBAf8ECDAGAQH/AgEBMB0GA1UdDgQWBBQV0UAx2FSuZgCwn3imOAf3xg5l
      PTAKBggqhkjOPQQDAgNHADBEAiBtVcB5tUcaUC8WfIr05qkbkLljHwCc3KB3DqNt
      zTd+BwIgettjvtpjTwrBw1JBph0P+75ugTvES8KOQQWqQUnMMz4=
      -----END CERTIFICATE-----
    ''
  ];

  services.openssh = {
    enable = !config.arcworks.network.tailnet.enable;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
