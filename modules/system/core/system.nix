{
  lib,
  hostConfig,
  ...
}: {
  config = {
    system.stateVersion = hostConfig.stateVersion;
    time.timeZone = hostConfig.timezone;
    networking.hostName = hostConfig.hostname;
    assertions = [
      {
        assertion = hostConfig.hostname != "";
        message = "System hostname cannot be empty";
      }
      {
        assertion = lib.hasPrefix "/" (toString hostConfig.homeDirectory);
        message = "Home directory must be an absolute path";
      }
    ];
  };
}
