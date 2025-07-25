{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.discord;
in {
  options.home.programs.discord = {
    enable = lib.mkEnableOption "Discord module";
    variant = lib.mkOption {
      type = lib.types.enum ["canary" "stable"];
      default = "canary";
      description = "Which Discord variant to install (canary or stable)";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid.packages = with pkgs; [
      (
        if cfg.variant == "canary"
        then
          (discord-canary.override {
            withOpenASAR = true;
            withVencord = true;
          })
        else
          (discord.override {
            withOpenASAR = true;
            withVencord = true;
          })
      )
    ];
  };
}
