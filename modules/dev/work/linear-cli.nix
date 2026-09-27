{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  linear-cli-src = flakeInputs.linear-cli;
  package = (import (toString flakeInputs.deno2nix) {inherit pkgs;}).lib.buildDenoPackage {
    pname = "linear";
    inherit ((builtins.fromJSON (builtins.readFile "${linear-cli-src}/deno.json"))) version;
    src = lib.cleanSource linear-cli-src;
    denoDepsHash = "sha256-C8xXrLd7h5SX7r8zjW7g5VRaN7mw+1LhE+nWoFfNjiA=";

    buildPhase = ''
      runHook preBuild
      deno run --no-check --cached-only --allow-all npm:@graphql-codegen/cli/graphql-codegen-esm
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/linear $out/bin $out/share/doc/linear $out/share/licenses/linear
      cp -r src graphql deno.json deno.lock $out/share/linear/
      cp -r vendor .deno node_modules $out/share/linear/
      cp README.md CHANGELOG.md $out/share/doc/linear/
      cp LICENSE $out/share/licenses/linear/
      cat > $out/bin/linear <<EOF
      #!${pkgs.runtimeShell}
      export DENO_DIR=$out/share/linear/.deno
      cd $out/share/linear
      exec ${pkgs.deno}/bin/deno run --no-check --cached-only --allow-all src/main.ts "\$@"
      EOF
      chmod +x $out/bin/linear
      runHook postInstall
    '';

    meta = {
      description = "CLI for Linear.app";
      homepage = "https://github.com/schpet/linear-cli";
      license = lib.licenses.mit;
      mainProgram = "linear";
      platforms = lib.platforms.linux;
    };
  };
in {
  options.user.dev.work.linear-cli.enable = lib.mkEnableOption "Linear CLI";

  config = lib.mkIf config.user.dev.work.linear-cli.enable {
    environment.systemPackages = [
      package
      pkgs.libsecret
    ];
  };
}
