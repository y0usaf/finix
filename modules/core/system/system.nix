{
  config,
  lib,
  ...
}: {
  options = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "System hostname";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "System timezone";
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version";
    };
  };

  config = {
    system.stateVersion = config.stateVersion;
    time.timeZone = config.timezone;
    networking.hostName = config.hostname;
    assertions = [
      {
        assertion = config.hostname != "";
        message = "System hostname cannot be empty";
      }
    ];
  };
}
