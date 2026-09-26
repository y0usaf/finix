{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.devin = {
    enable = lib.mkEnableOption "devin-cli package";
  };

  config = lib.mkIf config.user.dev.devin.enable {
    environment.systemPackages = [
      pkgs.devin-cli
    ];

    manzil.users."${config.user.name}".files = {
      ".config/devin/AGENTS.md".text =
        config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments;
      ".config/devin/config.json" = {
        type = "merge";
        format = "json";
        clobber = true;
        value = {
          attribution = false;
        };
      };
    };

    environment.variables.DEVIN_PERMISSION_MODE = "dangerous";
  };
}
