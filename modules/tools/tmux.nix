{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";

  config = lib.mkIf config.user.tools.tmux.enable {
    environment.systemPackages = [pkgs.tmux];
  };
}
