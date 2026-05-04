{
  config,
  lib,
  ...
}: {
  config =
    lib.mkIf (
      (config.user.programs.discord.stable.enable or false)
      || (config.user.programs.discord.canary.enable or false)
    ) {
      manzil.users."${config.user.name}".files.".config/Vencord/themes/disblock.css".text = ''
        :root {
          --display-clan-tags: none;
          --display-active-now: none;
          --display-hover-reaction-emoji: none;
          --bool-show-name-gradients: false;
        }
      '';
    };
}
