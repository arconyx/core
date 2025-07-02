# Cross compiling ruby is broken because rust continues to compile to match the host platform
#
# We just disable rust based yjit, which should mean we fall back on the regular ruby interpreter.
# According to https://docs.ruby-lang.org/en/3.4/yjit/yjit_md.html#label-Reducing+YJIT+Memory+Usage
# yjit uses more memory, so this is somewhat beneficial on our pis.
# (still slower though, probably)
#
# Attempts to patch yjit compliation are in previous commits. The problem is that it compiles
# yjit for the build platform. I was able to patch yjit.mk to target the host platform, but then
# there were issues with rustc provided by nix not including the toolchain for the ruby host platform.
# Attempts to supply rustc as depsBuildTarget to avoid this failed due to the cargo setup hook breaking.
# Ugh.

{
  lib,
  config,
  ...
}:
{
  # Rebuilding ruby requires rebuilding the world (I think because it is a transitive dependency of ffmpeg)
  # so let's only do it when we are cross compiling.
  nixpkgs.overlays = lib.mkIf (config.nixpkgs.hostPlatform != config.nixpkgs.buildPlatform) [
    (final: prev: {
      # This will apply even if yjitSupport is disabled, which isn't great but I can't find a way to check it in overrideAttrs.
      ruby = prev.ruby.override {
        yjitSupport = false;
      };
    })
  ];
}
