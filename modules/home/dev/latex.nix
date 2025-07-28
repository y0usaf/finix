{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.latex;
in {
  options.home.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = with pkgs; [
      texliveFull
      texstudio
      tectonic
    ];
  };
}
