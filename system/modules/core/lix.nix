{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.lix.enable = lib.mkEnableOption "whether to enable lix package";

  config = lib.mkIf config.programs.lix.enable {
    nix.package = pkgs.lix;
  };
}
