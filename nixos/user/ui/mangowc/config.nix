{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.mangowc.enable {
    # Enable mangowc at the system level
    programs.mango.enable = true;

    # Basic packages for mangowc usage
    environment.systemPackages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.jq
      pkgs.swaybg
    ];

    # Minimal configuration via hjem
    usr.files.".config/mango/config.conf".text = ''
      # MangoWC Configuration

      # Scroller Layout Settings
      scroller_default_proportion=0.5
      scroller_proportion_preset=0.33333,0.5,0.66667

      # Monitor Configuration
      # Format: name,mfact,nmaster,layout,transform,scale,x,y,width,height,refreshrate
      monitorrule=DP-4,0.55,1,scroller,0,1,0,0,5120,1440,240
      monitorrule=DP-2,0.55,1,scroller,0,1,0,0,5120,1440,240
      monitorrule=HDMI-A-2,0.55,1,scroller,0,1,5120,0,1920,1080,60

      # System
      bind=Alt+Shift,e,quit,
      bind=SUPER+Shift,r,reload_config,

      # Core Applications
      bind=Alt,t,spawn,${config.user.defaults.terminal}
      bind=SUPER,r,spawn,${config.user.defaults.launcher}
      bind=Alt,space,spawn,${config.user.defaults.launcher}
      bind=Alt,e,spawn,${config.user.defaults.fileManager}
      bind=SUPER+Shift,o,spawn,${config.user.defaults.terminal} -e ${config.user.defaults.editor}

      # Quick Launch Apps
      bind=Alt,1,spawn,${config.user.defaults.ide}
      bind=Alt,2,spawn,${config.user.defaults.browser}
      bind=Alt,3,spawn,vesktop
      bind=Alt,4,spawn,steam
      bind=Alt,5,spawn,obs

      # Window Management
      bind=Alt,q,killclient,
      bind=Alt,f,togglemaximizescreen,
      bind=Alt+Shift,f,togglefullscreen,
      bind=SUPER,space,togglefloating,
      bind=Alt,o,toggleoverview,

      # Window Resize (Scroller Layout)
      bind=Alt,r,switch_proportion_preset,

      # Focus Navigation (Vim Keys)
      bind=Alt,h,focusdir,left
      bind=Alt,j,focusdir,down
      bind=Alt,k,focusdir,up
      bind=Alt,l,focusdir,right

      # Focus Navigation (Arrow Keys)
      bind=Alt,Left,focusdir,left
      bind=Alt,Down,focusdir,down
      bind=Alt,Up,focusdir,up
      bind=Alt,Right,focusdir,right

      # Swap Windows (Vim Keys)
      bind=Alt+Shift,h,exchange_client,left
      bind=Alt+Shift,j,exchange_client,down
      bind=Alt+Shift,k,exchange_client,up
      bind=Alt+Shift,l,exchange_client,right

      # Swap Windows (Arrow Keys)
      bind=Alt+Shift,Left,exchange_client,left
      bind=Alt+Shift,Down,exchange_client,down
      bind=Alt+Shift,Up,exchange_client,up
      bind=Alt+Shift,Right,exchange_client,right

      # Workspace Switching
      bind=SUPER,1,view,0
      bind=SUPER,2,view,1
      bind=SUPER,3,view,2
      bind=SUPER,4,view,3
      bind=SUPER,5,view,4
      bind=SUPER,6,view,5
      bind=SUPER,7,view,6
      bind=SUPER,8,view,7
      bind=SUPER,9,view,8

      # Move to Workspace
      bind=SUPER+Shift,1,tag,0
      bind=SUPER+Shift,2,tag,1
      bind=SUPER+Shift,3,tag,2
      bind=SUPER+Shift,4,tag,3
      bind=SUPER+Shift,5,tag,4
      bind=SUPER+Shift,6,tag,5
      bind=SUPER+Shift,7,tag,6
      bind=SUPER+Shift,8,tag,7
      bind=SUPER+Shift,9,tag,8

      # Utilities
      bind=Alt,g,spawn_shell,grim -g "$(slurp)" - | wl-copy
      bind=Alt+Shift,g,spawn_shell,grim - | wl-copy
      bind=Alt+Shift,c,spawn_shell,killall swaybg; swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill &
    '';

    usr.files.".config/mango/autostart.sh".text = ''
      # Autostart commands
      swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill &
    '';
  };
}
