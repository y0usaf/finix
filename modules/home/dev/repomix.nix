{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.repomix;
in {
  options.home.dev.repomix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable repomix tool for AI-friendly repository packing";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        repomix
      ];
    };
  };
}
