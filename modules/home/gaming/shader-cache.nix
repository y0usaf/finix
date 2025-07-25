{config, ...}: {
  config = {
    users.users.y0usaf.maid.file.xdg_config."steam/steam_dev.cfg".text = ''
      unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
    '';
  };
}
