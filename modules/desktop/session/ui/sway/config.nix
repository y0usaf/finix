{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) appearance ui;
  inherit (appearance) cursorColor cursorSize;
  inherit (ui) sway;
  colorCap = let
    first = builtins.substring 0 1 cursorColor;
    rest = builtins.substring 1 (-1) cursorColor;
  in
    (lib.toUpper first) + rest;
  startupCommands =
    [
      "exec --no-startup-id sh -c 'swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill'"
    ]
    ++ lib.optional ui.vicinae.enable "exec --no-startup-id ${pkgs.vicinae}/bin/vicinae server"
    ++ lib.optional (ui.gpuishell.enable or false) "exec --no-startup-id ${pkgs.gpuishell}/bin/gpuishell"
    ++ lib.optional (ui.quickshell.enable or false) "exec --no-startup-id quickshell"
    ++ lib.optional (ui.ags.bar-overlay.enable or false) "exec --no-startup-id ${ui.ags.package}/bin/ags run /home/${config.user.name}/.config/ags/bar-overlay.tsx"
    ++ lib.optional (config.user.programs.handy.enable or false) "exec --no-startup-id handy";
in {
  config = lib.mkIf sway.enable (lib.mkMerge [
    {
      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        extraOptions = lib.optionals config.hardware.nvidia.enable ["--unsupported-gpu"];
      };

      environment.systemPackages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard-rs
        pkgs.swaybg
        pkgs.hyprpicker
        pkgs.brightnessctl
        pkgs.playerctl
      ];

      bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkBefore ''
        include /etc/sway/config.d/*

        set $mod Mod1
        set $mod2 Mod4
        set $term ${config.user.defaults.terminal}
        set $filemanager ${config.user.defaults.fileManager}
        set $browser ${config.user.defaults.browser}
        set $discord ${config.user.defaults.discord}
        set $launcher ${config.user.defaults.launcher}
        set $ide ${config.user.defaults.ide}
        set $notepad ${config.user.defaults.terminal} -e ${config.user.defaults.editor}
        set $obs obs

        floating_modifier $mod normal

        seat seat0 xcursor_theme Popucom-${colorCap}-x11 ${toString cursorSize}

        for_window [app_id="launcher"] floating enable
        for_window [app_id="launcher"] resize set width 800 px height 600 px
        for_window [app_id="launcher"] move position center

        ${lib.concatLines startupCommands}
      '';
    }

    (lib.mkIf (sway.extraConfig != "") {
      bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkAfter sway.extraConfig;
    })
  ]);
}
