{
  config,
  lib,
  hostConfig,
  ...
}: {
  config = {
    system.stateVersion = hostConfig.stateVersion;
    time.timeZone = hostConfig.timezone;
    networking.hostName = hostConfig.hostname;
    nixpkgs.config.allowUnfree = true;
    assertions = [
      {
        assertion = (builtins.head hostConfig.users) != "";
        message = "System username cannot be empty";
      }
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
