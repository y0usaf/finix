{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.work.linear-cli;
  tomlFormat = pkgs.formats.toml {};

  # Rebuild the `linear` package locally instead of using
  # flakeInputs.linear-cli.packages.${system}.default. The linear-cli flake
  # is a dead wrapper (a clone of schpet/linear-cli plus a flake) and its
  # pinned `denoDepsHash` is stale — `linear-2.0.0-deno-deps` fails with a
  # fixed-output hash mismatch. We vendor deno2nix (the same build tooling
  # linear-cli's flake uses, pinned to the same ref) and rebuild `linear`
  # from the linear-cli source tree with the corrected deps hash. Mirrors
  # the build/install phases of linear-cli's flake.nix.
  linear-cli-src = flakeInputs.linear-cli;
in {
  options.user.dev.work.linear-cli = {
    enable = lib.mkEnableOption "Linear CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = (import flakeInputs.deno2nix {inherit pkgs;}).lib.buildDenoPackage {
        pname = "linear";
        inherit ((builtins.fromJSON (builtins.readFile "${linear-cli-src}/deno.json"))) version;
        src = lib.cleanSource linear-cli-src;
        # Corrected FOD hash; upstream linear-cli pins the stale
        # sha256-jGqice4hH4RW2o7Q4VhwUm8G/EUb98AdJ/Z1jrXMeGE=.
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
      description = "Linear CLI package to install.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = {};
      description = "Linear CLI settings written to ~/.config/linear/linear.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.libsecret
    ];

    manzil.users."${config.user.name}".files = lib.optionalAttrs (builtins.length (builtins.attrNames cfg.settings) > 0) {
      ".config/linear/linear.toml" = {
        source = tomlFormat.generate "linear-cli-config" cfg.settings;
      };
    };
  };
}
