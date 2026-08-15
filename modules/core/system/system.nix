{
  lib,
  ...
}: {
  # hostname/timezone/stateVersion options. The config wiring them to
  # system.stateVersion / time.timeZone / networking.hostName and the
  # hostname assertion was NixOS-only (dropped by the compat shim); finix sets
  # hostname/timezone natively in hosts/.../finix.
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
}