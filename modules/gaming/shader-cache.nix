{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.core.enable {
    manzil.users."${config.user.name}".files.".config/steam/steam_dev.cfg" = {
      text = ''
        unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
      '';
    };
  };
}
