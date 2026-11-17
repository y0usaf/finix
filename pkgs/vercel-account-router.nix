{pkgs, ...}: let
  inherit (pkgs) lib;
  version = "59.5.0";
  package = pkgs.buildNpmPackage {
    pname = "vercel";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/vercel/-/vercel-${version}.tgz";
      hash = "sha256-1I4UY37yiStRActe+cDvTWIQ1/c4QqDp9DKumkp3NBQ=";
    };
    sourceRoot = "package";

    postPatch = ''
      cp ${../modules/dev/work/vercel/package.json} package.json
      cp ${../locks/package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-4TBcL7MbOq51n0DKHdOUgp4amf2ZAl7bMPErggHQL0c=";
    dontNpmBuild = true;

    meta = {
      description = "The command-line interface for Vercel";
      homepage = "https://vercel.com";
      license = lib.licenses.asl20;
      mainProgram = "vercel";
      platforms = lib.platforms.unix;
    };
  };
in
  pkgs.runCommand "vercel-account-router" {} ''
    mkdir -p $out/bin
    cat > $out/bin/vercel <<EOF
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3}/bin/python3 ${pkgs.replaceVars ../modules/dev/work/vercel/wrapper.py {
      vercel = package;
      inherit (pkgs) git;
      owners = builtins.toJSON {y0usaf = "personal";};
    }} "\$@"
    EOF
    for account in personal work; do
      cat > $out/bin/vercel-$account <<EOF
    #!${pkgs.runtimeShell}
    export VERCEL_ACCOUNT=$account
    exec $out/bin/vercel "\$@"
    EOF
    done
    chmod +x $out/bin/*
  ''
