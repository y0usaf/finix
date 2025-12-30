{pkgs, ...}: {
  # Set display resolution to 3456x2234
  # This uses a launchd agent to apply display preferences on startup

  launchd.agents.set-display-resolution = {
    script = ''
      # Set display resolution to 3456x2234
      # Using defaults write to store resolution preference
      defaults write /Library/Preferences/com.apple.windowserver DisplayResolution -string "3456x2234"
    '';
    serviceConfig = {
      RunAtLoad = true;
      StandardOutPath = "/var/log/set-display-resolution.log";
      StandardErrorPath = "/var/log/set-display-resolution.log";
    };
  };
}
