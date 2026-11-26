{
  config,
  pkgs,
  ...
}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir runtimeDirReady;
in {
  environment.systemPackages = [pkgs.udiskie];

  finit.services = {
    ssh-agent = {
      description = "ssh-agent (${userName})";
      user = userName;
      environment = {
        HOME = home;
        XDG_RUNTIME_DIR = runtimeDir;
      };
      conditions = [runtimeDirReady];
      command = "${pkgs.openssh}/bin/ssh-agent -D -a ${runtimeDir}/ssh-agent";
      log = true;
    };

    udiskie = {
      description = "udiskie automount (${userName})";
      user = userName;
      environment = {
        HOME = home;
        XDG_RUNTIME_DIR = runtimeDir;
      };
      command = "${pkgs.udiskie}/bin/udiskie --automount";
      conditions = ["net/lo/up" runtimeDirReady];
      log = true;
    };
  };
}
