{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  grok-bot = flakeInputs.grok-bot.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/silvabot"
    ".grokbot"
    ".local/share/silvabot"
    ".local/state/silvabot"
  ];
  environment.systemPackages = [
    (grok-bot.override {
      commandLineArgs = [
        "--force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale}"
      ];
    })
  ];
}
