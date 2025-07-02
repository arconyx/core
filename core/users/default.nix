{ pkgs, lib, ... }:
{
  imports = [ ./users.nix ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  arcworks.users = {
    arc = {
      enable = true;
      description = lib.mkDefault "ArcOnyx"; # we often want to override this with real name
      isAdmin = true;
      shell = pkgs.fish;
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAZIiEClyJTtGDp3mB8hHfqrdlk5b1qoZUZFXlRUTgOt arc@tardis"
        # this is a public key but ripsecrets picks it up - probably because it looks like a long random string
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC31VR2wRvZYmzyGce0voJ8Ye037xYLxvQDaU48FcBzMKbbS4uryfCUt6wg6WjzTmr/kWbnLdYNQRTg7qUXWzbmYhL1TNPYRDogpnMbs387fDWhCcth7RRHbYWFnbthWUo11PPUnpbfsbfBPYKbfK96lTj6RaWYUSyNhnvrD5Z3JQJu3EILaGS+lE9tky/OsHXfAX0OvepQTkm3IFxG4uiEuQ3dh0XtiofToulHesi+EjviZh+ck1XZGUNLqjGsNfHOp6mzahY3Pal/2bmKT6OA68GisFbzfdVbL6lL1u3wQlu4o5iuebEFAIuek5HIx4MNG9+eJK1oGTycJv22dumXnZcP5O4tHppfuIMm5nsh374wu3vcPCpDGJ1KUmuYRLAAhMX45xEpfwVlo33r5EQ/DOkG308CW+sULk9iSKYDyyqf3rZ+096RtwEe6HGqpIahJ0ZtirtuzbEa32idDcaacA1GfS2zC5Ds+VzCko3/8gaCqPclhyzzJb+tFsV+258= arc@phoenix" # pragma: allowlist secret
      ];
    };
  };
}
