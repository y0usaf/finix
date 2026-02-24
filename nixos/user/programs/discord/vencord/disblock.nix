{
  config,
  lib,
  ...
}: let
  stableEnabled = config.user.programs.discord.stable.enable or false;
  canaryEnabled = config.user.programs.discord.canary.enable or false;
  discordEnabled = stableEnabled || canaryEnabled;
in {
  config = lib.mkIf discordEnabled {
    hjem.users.${config.user.name}.files.".config/Vencord/themes/disblock.css".text = ''
      :root {
        --display-clan-tags: none;
        --display-active-now: none;
        --display-hover-reaction-emoji: none;
        --bool-show-name-gradients: false;
      }
    '';
  };
}
