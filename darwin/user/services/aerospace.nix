{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.users.y0usaf = {
    # AeroSpace autostart via launchd
    launchd.agents.aerospace = lib.mkIf config.user.wm.aerospace.enable {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.aerospace}/bin/aerospace"
        ];
        RunAtLoad = true;
        StandardErrorPath = "/tmp/aerospace-error.log";
        StandardOutPath = "/tmp/aerospace.log";
        KeepAlive = true;
      };
    };

    # AeroSpace - tiling window manager with vim keybindings
    home.packages = lib.optionals config.user.wm.aerospace.enable (with pkgs; [
      aerospace
    ]);

    xdg.configFile."aerospace/aerospace.toml" = lib.mkIf config.user.wm.aerospace.enable {
      text = ''
        # AeroSpace configuration with vim-style keybindings

        start-at-login = true
        enable-normalization-flatten-containers = true
        enable-normalization-opposite-orientation-for-nested-containers = true

        default-root-container-layout = 'tiles'
        default-root-container-orientation = 'auto'

        [gaps]
        inner.horizontal = 8
        inner.vertical = 8
        outer.left = 8
        outer.bottom = 8
        outer.top = 8
        outer.right = 8

        [mode.main.binding]
        # Vim-style window focus navigation
        alt-h = 'focus left'
        alt-j = 'focus down'
        alt-k = 'focus up'
        alt-l = 'focus right'

        # Vim-style window movement
        alt-shift-h = 'move left'
        alt-shift-j = 'move down'
        alt-shift-k = 'move up'
        alt-shift-l = 'move right'

        # App launchers
        alt-d = 'exec-and-forget open -n -a Alacritty'
        cmd-2 = 'exec-and-forget open -n -a Librewolf'

        # Workspace switching
        alt-1 = 'workspace 1'
        alt-2 = 'workspace 2'
        alt-3 = 'workspace 3'
        alt-4 = 'workspace 4'
        alt-5 = 'workspace 5'
        alt-6 = 'workspace 6'
        alt-7 = 'workspace 7'
        alt-8 = 'workspace 8'
        alt-9 = 'workspace 9'

        # Move window to workspace
        alt-shift-1 = 'move-node-to-workspace 1'
        alt-shift-2 = 'move-node-to-workspace 2'
        alt-shift-3 = 'move-node-to-workspace 3'
        alt-shift-4 = 'move-node-to-workspace 4'
        alt-shift-5 = 'move-node-to-workspace 5'
        alt-shift-6 = 'move-node-to-workspace 6'
        alt-shift-7 = 'move-node-to-workspace 7'
        alt-shift-8 = 'move-node-to-workspace 8'
        alt-shift-9 = 'move-node-to-workspace 9'

        # Layout management
        alt-slash = 'layout tiles horizontal vertical'
        alt-comma = 'layout accordion horizontal vertical'
        alt-shift-f = 'layout floating tiling'

        # Window management
        alt-f = 'fullscreen'
        alt-shift-q = 'close'
        alt-r = 'mode resize'
        alt-shift-r = 'reload-config'

        # Resize mode (vim-style with hjkl)
        [mode.resize.binding]
        h = 'resize width -50'
        j = 'resize height +50'
        k = 'resize height -50'
        l = 'resize width +50'
        esc = 'mode main'
        enter = 'mode main'
      '';
    };
  };
}
