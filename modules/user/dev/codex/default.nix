{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.codex = {
    enable = lib.mkEnableOption "OpenAI Codex";
  };

  config = lib.mkIf config.user.dev.codex.enable {
    environment.systemPackages = [
      pkgs.codex
    ];
  };
}
