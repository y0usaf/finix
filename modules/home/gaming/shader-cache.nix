{config, ...}: {
  config = {
    users.users.${config.user.name}.maid.file.xdg_config."steam/steam_dev.cfg".text = ''
      unShaderBackgroundProcessingThreads ${toString config.nix.settings.max-jobs}
    '';
  };
}
