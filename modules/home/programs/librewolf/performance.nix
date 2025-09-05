{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  commonSettings = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
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
    "browser.sessionstore.interval" = 15000;
    "network.http.max-persistent-connections-per-server" = 10;
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 1048576;
    "browser.sessionhistory.max_entries" = 50;
    "network.prefetch-next" = true;
    "network.dns.disablePrefetch" = false;
    "network.predictor.enabled" = true;
    "browser.tabs.drawInTitlebar" = true;
    "browser.theme.toolbar-theme" = 0;
    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;
    "devtools.debugger.prompt-connection" = false;
    "browser.enabledE10S" = false;
    "browser.theme.dark-private-windows" = false;
    "dom.webcomponents.enabled" = true;
    "layout.css.shadow-parts.enabled" = true;
  };
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
  config = lib.mkIf config.home.programs.librewolf.enable {
    hjem.users.${username} = {
      files = {
        ".mozilla/librewolf/${username}.default/user.js" = {
          text = userJsContent;
          clobber = true;
        };
        ".mozilla/librewolf/${username}.default-release/user.js" = {
          text = userJsContent;
          clobber = true;
        };
      };
    };
  };
}
