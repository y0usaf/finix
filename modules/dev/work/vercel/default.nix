{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.work.vercel;
  version = "59.5.0";
in {
  options.user.dev.work.vercel = {
    enable = lib.mkEnableOption "Vercel CLI";

    package = lib.mkOption {
      type = lib.types.package;
      # The npm tarball ships prebuilt dist/ — no JS build step. Its
      # devDependencies (@vercel-internals/*) are unpublished on the public
      # registry, so the vendored package.json here is the upstream one with
      # that section pruned; the matching lockfile sits beside it and npm ci's
      # sync check stays satisfied.
      default = pkgs.buildNpmPackage {
        pname = "vercel";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/vercel/-/vercel-${version}.tgz";
          hash = "sha256-1I4UY37yiStRActe+cDvTWIQ1/c4QqDp9DKumkp3NBQ=";
        };
        sourceRoot = "package";

        postPatch = ''
          cp ${./package.json} package.json
          cp ${./package-lock.json} package-lock.json
        '';

        npmDepsHash = "sha256-4TBcL7MbOq51n0DKHdOUgp4amf2ZAl7bMPErggHQL0c=";
        dontNpmBuild = true;

        meta = {
          description = "The command-line interface for Vercel";
          homepage = "https://github.com/vercel/vercel";
          license = lib.licenses.asl20;
          mainProgram = "vercel";
          platforms = lib.platforms.unix;
        };
      };
      description = "Vercel CLI package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
