{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.codex;
in {
  options.home.dev.codex = {
    enable = lib.mkEnableOption "OpenAI Codex";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.codex
    ];
  };
}
