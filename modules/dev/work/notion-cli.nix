{
  config,
  lib,
  pkgs,
  ...
}: let
  version = "0.0.0";
in {
  options.user.dev.work.notion-cli = {
    enable = lib.mkEnableOption "Notion CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "notion-cli";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/notion-cli/-/notion-cli-${version}.tgz";
          hash = "sha256-EbOwcr4DtfIY5klzs4RIRRjEn4BCFRehZGJkzh2sDzY=";
        };

        dontUnpack = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          tar -xzf $src --strip-components=1 -C $out
          chmod +x $out/cli.js
          ln -s $out/cli.js $out/bin/notion
          runHook postInstall
        '';

        meta = {
          description = "CLI for Notion";
          homepage = "https://github.com/bntzio/notion-cli";
          license = lib.licenses.mit;
          mainProgram = "notion";
          platforms = lib.platforms.unix;
        };
      };
      description = "Notion CLI package to install.";
    };
  };

  config = lib.mkIf config.user.dev.work.notion-cli.enable {
    environment.systemPackages = [
      config.user.dev.work.notion-cli.package
    ];
  };
}
