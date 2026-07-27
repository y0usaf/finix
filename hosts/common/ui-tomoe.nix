# Shared tomoe UI base for the two graphical tomoe hosts (y0usaf-desktop
# ultrawide, y0usaf-framework laptop). Pulled in via explicit `imports` from
# each host's ui.nix — hosts/common/ is outside every recursivelyImport
# domain, so this module never loads unless a host asks for it (keeps it
# away from the niri laptop and the server).
#
# Host files keep only what is genuinely per-host: displays, layout, bar
# shape, and machine-specific Lua hooks. The launcher floating rule and
# client-fullscreen opt-in were duplicated (or, for fullscreen, dropped on
# the desktop by accident — see commit 252262af, framework-only) before
# this extraction.
{lib, ...}: {
  user.ui = {
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    wayland.enable = true;

    tomoe = {
      enable = true;
      bar.bongo-cat.enable = true;

      # mkBefore: host extraConfig (lines type) appends after this chunk.
      extraConfig = lib.mkBefore ''
        -- Browser/video/game controls may request real output fullscreen.
        wm.honor_client_fullscreen = true
        -- Keep the dmenu-style launcher out of the tiling (split tree / deck).
        tomoe.rule { app_id = "^launcher$", floating = true }
      '';
    };
  };
}
