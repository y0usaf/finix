{...}: {
  imports = [
    ./debloat.nix
    ./keyboard.nix
    ./trackpad.nix
    ./finder.nix
    ./screenshot.nix
    ./performance.nix
  ];

  system = {
    primaryUser = "y0usaf";

    defaults = {
      LaunchServices.LSQuarantine = false;

      NSGlobalDomain = {
        _HIHideMenuBar = true;
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        show-recents = false;
        static-only = true;
        tilesize = 16;
      };
    };
  };

  system.defaults.CustomSystemPreferences = {
    "com.apple.assistant.support" = {
      "Assistant Enabled" = 0;
    };
    "com.apple.windowserver" = {
      "DisplayResolution" = "3456x2234";
    };
  };
}
