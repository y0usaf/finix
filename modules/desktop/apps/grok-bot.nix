{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  grokBotCfg = config.user.programs.grok-bot;
  # Consume the source flake's own package output: it pins its nixpkgs and
  # sets allowUnfree itself (unfree Anysphere/XAI artifacts).
  grok-bot = flakeInputs.grok-bot.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  options.user.programs.grok-bot = {
    enable = mkEnableOption "Grok Bot 0.18 reconstructed (Linux port, standalone mode)";
  };

  config = mkIf grokBotCfg.enable {
    environment.systemPackages = [
      grok-bot
    ];
  };
}
