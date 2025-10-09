{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.discord = {
    enable = lib.mkEnableOption "Discord module";
    variant = lib.mkOption {
      type = lib.types.enum ["canary" "stable"];
      default = "canary";
      description = "Which Discord variant to install (canary or stable)";
    };
  };
  config = lib.mkIf config.user.programs.discord.enable {
    environment.systemPackages = [
      (
        if config.user.programs.discord.variant == "canary"
        then
          (pkgs.discord-canary.override {
            withOpenASAR = true;
            withVencord = true;
          })
        else
          (pkgs.discord.override {
            withOpenASAR = true;
            withVencord = true;
          })
      )
    ];
  };
}
