{
  config,
  lib,
  ...
}: let
  # `$term` is only ever used to *spawn* a terminal (Mod+T, which-key T);
  # `$notepad` embeds `defaults.terminal -e` directly, so routing the spawn
  # through `ekko open` (user.shell.ekko.open) is safe here.
  ekkoOpen = config.user.shell.ekko.enable && config.user.shell.ekko.open;
  termSpawn =
    if ekkoOpen
    then "ekko open"
    else config.user.defaults.terminal;
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkBefore ''
        $mod = ALT
        $mod2 = SUPER
        $term = ${termSpawn}
        $filemanager = ${config.user.defaults.fileManager}
        $browser = ${config.user.defaults.browser}
        $discord = ${config.user.defaults.discord}
        $launcher = ${config.user.defaults.launcher}
        $ide = ${config.user.defaults.ide}
        $notepad = ${config.user.defaults.terminal} -e ${config.user.defaults.editor}
        $obs = obs
        ${lib.optionalString ekkoOpen "env = TERMINAL,${config.user.defaults.terminal}"}
      '';
    };
  };
}
