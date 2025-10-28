{...}: {
  imports = [
    ./options.nix
    ./core
    ./shell
    ./dev
    ./tools
    ./services
    ./ui
    ./programs
  ];

  config.user = {
    wm.aerospace.enable = true;
    tools.raycast.enable = true;
    ui.jankyborders.enable = true;
    programs.librewolf.enable = true;
    shell.zellij = {
      enable = true;
      autoStart = true;
      zjstatus.enable = true;
      zjstatusHints.enable = true;
    };
  };
}
