{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.work.vercel;
  version = "59.5.0";
  owners = builtins.listToAttrs (
    map (name: {
      name = pkgs.lib.toLower name;
      value = "personal";
    })
    cfg.personalOwners
    ++ map (name: {
      name = pkgs.lib.toLower name;
      value = "work";
    })
    cfg.workOwners
  );
  script = pkgs.replaceVars ./wrapper.py {
    vercel = cfg.package;
    inherit (pkgs) git;
    owners = builtins.toJSON owners;
  };
in {
  options.user.dev.work.vercel = {
    enable = lib.mkEnableOption "Vercel CLI";

    personalOwners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["y0usaf"];
      description = "GitHub origin owners routed to the personal Vercel login.";
    };
    workOwners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "GitHub origin owners routed to the work Vercel login.";
    };

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
  options.user.dev.work.vercel.wrappedPackage = lib.mkOption {
    type = lib.types.package;
    description = "Vercel CLI with account routing.";
    default = pkgs.runCommand "vercel-account-router" {} ''
      mkdir -p $out/bin
      cat > $out/bin/vercel <<EOF
      #!${pkgs.runtimeShell}
      exec ${pkgs.python3}/bin/python3 ${script} "\$@"
      EOF
      for account in personal work; do
        cat > $out/bin/vercel-$account <<EOF
      #!${pkgs.runtimeShell}
      export VERCEL_ACCOUNT=$account
      exec $out/bin/vercel "\$@"
      EOF
      done
      chmod +x $out/bin/*
    '';
  };
}
