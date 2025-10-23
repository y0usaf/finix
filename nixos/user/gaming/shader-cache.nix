{config, ...}: {
  config = {
    usr.files.".config/steam/steam_dev.cfg" = {
      text = ''
        unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
      '';
      clobber = true;
    };
  };
}
