{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";

  config = lib.mkIf config.user.tools.tmux.enable {
    environment.systemPackages = [pkgs.tmux];

    programs.tmux = {
      enable = true;
      # firstmate spawns crewmate windows in a tmux session
      # (docs/tmux-backend.md: tmux is the reference runtime backend).
      mouse = true;
    };
  };
}
