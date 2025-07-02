# Cross compiling PHP is broken because opcache wants access to a build system compiler
#

{
  lib,
  config,
  ...
}:
{
  # let's only do apply it when we are cross compiling.
  nixpkgs.overlays = lib.mkIf (config.nixpkgs.hostPlatform != config.nixpkgs.buildPlatform) [
    (final: prev: {
      php = prev.php.override {
        packageOverrides = finalPkg: prevPkg: {
          extensions = prevPkg.extensions // {
            opcache = prevPkg.extensions.opcache.overrideAttrs (attrs: {
              depsBuildBuild = attrs.depsBuildBuild or [ ] ++ [ prev.buildPackages.stdenv.cc ];
            });
          };
        };
      };
    })
  ];
}
