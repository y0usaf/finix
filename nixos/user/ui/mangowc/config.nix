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

      # Keybindings
      bind=Alt,Return,spawn,${pkgs.foot}/bin/foot
      bind=Alt,Space,spawn,${config.user.defaults.launcher}
      bind=Alt,q,killclient
      bind=Alt,left,focusdir,left
      bind=Alt,right,focusdir,right
      bind=Alt,up,focusdir,up
      bind=Alt,down,focusdir,down
      bind=SUPER,m,quit
    '';

    usr.files.".config/mango/autostart.sh".text = ''
      # Autostart commands
      swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill &
    '';
  };
}
