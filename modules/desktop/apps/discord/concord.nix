{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.user.programs.discord.concord;
in {
  options.user.programs.discord.concord = {
    enable = mkEnableOption "Concord Discord client";

    package = mkOption {
      type = types.package;
      default = flakeInputs.concord.packages."${pkgs.stdenv.hostPlatform.system}".default;
      description = "Concord package to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
