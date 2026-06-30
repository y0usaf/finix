{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.agent-slack = {
    enable = lib.mkEnableOption "agent-slack CLI";
  };

  config = lib.mkIf config.user.dev.work.agent-slack.enable {
    environment.systemPackages = [
      (pkgs.stdenvNoCC.mkDerivation {
        pname = "agent-slack";
        version = "0.9.3";

        src =
          pkgs.fetchurl {
            url = "https://github.com/stablyai/agent-slack/releases/download/v0.9.3/${
              {
                aarch64-darwin = "agent-slack-darwin-arm64";
                x86_64-darwin = "agent-slack-darwin-x64";
                aarch64-linux = "agent-slack-linux-arm64";
                x86_64-linux = "agent-slack-linux-x64";
              }
        ."${pkgs.stdenv.hostPlatform.system}"
        or (throw "agent-slack: unsupported system '${pkgs.stdenv.hostPlatform.system}'")
            }";
            hash =
              {
                aarch64-darwin = "sha256-ISvecKk6btX0kRyOc4jLH1a1HuCFABa8K9VbdByiBZY=";
                x86_64-darwin = "sha256-zsL7JR1YjygD77i/JCHwz0G5TUuQWPSy36e1D7zO2Ds=";
                aarch64-linux = "sha256-kcxLXERyKsIHu6o+RuJwi9rfZyOHYQMecWsYRbD2Y1Y=";
                x86_64-linux = "sha256-x6ZyNXh/vUDRRuYGWREeotbfuqerQU9mb1gf1nnQXsc=";
              }
        ."${pkgs.stdenv.hostPlatform.system}"
        or (throw "agent-slack: missing hash for system '${pkgs.stdenv.hostPlatform.system}'");
          };

        dontUnpack = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/agent-slack"
          runHook postInstall
        '';

        meta = {
          description = "Slack automation CLI for AI agents";
          homepage = "https://github.com/stablyai/agent-slack";
          license = lib.licenses.mit;
          mainProgram = "agent-slack";
          sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
        };
      })
    ];
  };
}
