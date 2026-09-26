{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.crush = {
    enable = lib.mkEnableOption "crush package";
  };

  config = lib.mkIf config.user.dev.crush.enable {
    environment.systemPackages = [
      pkgs.crush
    ];

    manzil.users."${config.user.name}".files.".config/crush/CRUSH.md".text =
      config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments;
  };
}
