{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };
  config = lib.mkIf config.user.dev.latex.enable {
    environment.systemPackages = [
      pkgs.texliveFull
      pkgs.texstudio
      pkgs.tectonic
    ];
  };
}
