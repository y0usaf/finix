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
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/crush"
      ".crush"
      ".local/share/crush"
    ];
    environment.systemPackages = [
      pkgs.crush
    ];

    manzil.users."${config.user.name}".files.".config/crush/CRUSH.md".text =
      config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments;
  };
}
