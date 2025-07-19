###############################################################################
# Firefox Performance Settings Module
# Common settings for Firefox profiles with hardware acceleration and performance optimizations
###############################################################################
{
  config,
  lib,
  ...
}: let
  username = "y0usaf";

  # Common settings for Firefox profiles
  commonSettings = {
    # Enable userChrome customizations (needed for the CSS)
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Disable hardware acceleration if using Nvidia
    "gfx.webrender.all" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.hardware-video-decoding.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.ffmpeg.vaapi.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "layers.acceleration.disabled" =
      if config.system.hardware.nvidia.enable or false
      then true
      else false;

    # Performance settings
    "browser.sessionstore.interval" = 15000; # Reduce writes to disk (default 15000)
    "network.http.max-persistent-connections-per-server" = 10; # Increase connections per server
    "browser.cache.disk.enable" = false; # Disable disk cache in favor of memory cache
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 1048576; # 1GB memory cache
    "browser.sessionhistory.max_entries" = 50; # Reduce memory usage from session history
    "network.prefetch-next" = true; # Enable link prefetching
    "network.dns.disablePrefetch" = false;
    "network.predictor.enabled" = true;

    # Basic UI settings
    "browser.tabs.drawInTitlebar" = true;
    "browser.theme.toolbar-theme" = 0;

    # Enable Browser Toolbox and development features
    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;
    "devtools.debugger.prompt-connection" = false;
    "browser.enabledE10S" = false;

    # Theme and UI settings
    "browser.theme.dark-private-windows" = false;

    # Development settings
    "dom.webcomponents.enabled" = true;
    "layout.css.shadow-parts.enabled" = true;
  };

  # Generate user.js content for Firefox profile
  userJsContent = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      key: value: let
        jsValue =
          if builtins.isBool value
          then
            (
              if value
              then "true"
              else "false"
            )
          else if builtins.isInt value
          then toString value
          else if builtins.isString value
          then ''"${value}"''
          else toString value;
      in ''user_pref("${key}", ${jsValue});''
    )
    commonSettings
  );
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    users.users.${username}.maid = {
      file.home = {
        # Default profile user.js (will be created if profile exists)
        ".mozilla/firefox/${username}.default/user.js".text = userJsContent;
        # Alternative profile paths (Firefox creates different profile names)
        ".mozilla/firefox/${username}.default-release/user.js".text = userJsContent;
      };
    };
  };
}
