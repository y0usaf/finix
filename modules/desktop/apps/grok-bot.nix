{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  grokBotCfg = config.user.programs.grok-bot;
  grok-bot = flakeInputs.grok-bot.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  options.user.programs.grok-bot = {
    enable = mkEnableOption "Grok Bot 0.18 reconstructed (Linux port, standalone mode)";
  };

  config = mkIf grokBotCfg.enable {
    environment.systemPackages = [
      (grok-bot.override {
        commandLineArgs = [
          "--force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale}"
        ];
      })
    ];
  };
}
