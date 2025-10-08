{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.dev.codex = {
    enable = lib.mkEnableOption "OpenAI Codex";
  };

  config = lib.mkIf config.home.dev.codex.enable {
    environment.systemPackages = [
      pkgs.codex
    ];
  };
}
