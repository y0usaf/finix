{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };
  config = lib.mkIf config.home.dev.latex.enable {
    environment.systemPackages = [
      pkgs.texliveFull
      pkgs.texstudio
      pkgs.tectonic
    ];
  };
}
