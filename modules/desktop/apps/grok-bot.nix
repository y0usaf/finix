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
      # Electron ignores GDK_DPI_SCALE, so the host's GTK scale reaches it as a
      # Chromium switch — the same mechanism obsidian.nix uses. The package's
      # own wrapper carries the flag, keeping the desktop entry's Exec plain.
      (grok-bot.override {
        commandLineArgs = [
          "--force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale}"
        ];
      })
    ];
  };
}
