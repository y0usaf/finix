{config, ...}: {
  config = {
    hjem.users.${config.user.name}.files.".config/steam/steam_dev.cfg" = {
      text = ''
        unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
      '';
      clobber = true;
    };
  };
}
