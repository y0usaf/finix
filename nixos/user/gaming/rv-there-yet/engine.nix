{
  config,
  lib,
  ...
}: {
  options.user.gaming.rv-there-yet.engine = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable RV There Yet engine configuration";
    };
  };
  config = lib.mkIf config.user.gaming.rv-there-yet.engine.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/3949040/pfx/drive_c/users/steamuser/AppData/Local/Ride/Saved/Config/Windows/Engine.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "GameNetDriver StatelessConnectHandlerComponent" = {
          CachedClientID = "11";
        };
      };
    };
  };
}
