{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "agent-slack";
      version = "0.10.0";
      nativeBuildInputs = [pkgs.patchelf];

      src = pkgs.fetchurl {
        url = "https://github.com/stablyai/agent-slack/releases/download/v0.10.0/agent-slack-linux-x64";
        hash = "sha256-tbnTqhnyO+hxAyuey4LEw/HC1xTrY8Ee4J1i/wV8yt4=";
      };

      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/agent-slack"
        patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$out/bin/agent-slack"
        runHook postInstall
      '';

      meta = {
        description = "Slack automation CLI for AI agents";
        homepage = "https://github.com/stablyai/agent-slack";
        license = lib.licenses.mit;
        mainProgram = "agent-slack";
        platforms = ["x86_64-linux"];
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
    })
  ];
}
