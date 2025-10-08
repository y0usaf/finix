{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.programs.discord = {
    enable = lib.mkEnableOption "Discord module";
    variant = lib.mkOption {
      type = lib.types.enum ["canary" "stable"];
      default = "canary";
      description = "Which Discord variant to install (canary or stable)";
    };
  };
  config = lib.mkIf config.home.programs.discord.enable {
    environment.systemPackages = [
      (
        if config.home.programs.discord.variant == "canary"
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
