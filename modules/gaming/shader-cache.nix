{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.core.enable {
    bayt.users."${config.user.name}".files.".config/steam/steam_dev.cfg" = {
      text = ''
        unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
      '';
    };
  };
}
