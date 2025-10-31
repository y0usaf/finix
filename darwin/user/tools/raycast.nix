{
  config,
  lib,
  ...
}: {
  home-manager.users.y0usaf = lib.mkIf config.user.tools.raycast.enable {
    launchd.agents.raycast = {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/bash"
          "-c"
          "open -a Raycast"
        ];
        RunAtLoad = true;
        StandardErrorPath = "/tmp/raycast-error.log";
        StandardOutPath = "/tmp/raycast.log";
      };
    };
  };
}
