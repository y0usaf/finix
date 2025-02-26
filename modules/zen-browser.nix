{ lib, config, pkgs, profile, ... }:
with lib;
let
  logoPath = ./logo.png;
  src = builtins.fetchurl {
    url = "https://github.com/zen-browser/desktop/releases/latest/download/zen-x86_64.AppImage";
    sha256 = "16k37ngl4qpqwwj6f9q8jpn20pk8887q8zc0l7qivshmhfib36qq";
  };

  # Reuse your Firefox settings and CSS
  commonSettings = {
    # Enable userChrome customizations
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Nvidia-specific settings
    "gfx.webrender.all" = !(builtins.elem "nvidia" profile.features);
    "media.hardware-video-decoding.enabled" = !(builtins.elem "nvidia" profile.features);
    "media.ffmpeg.vaapi.enabled" = !(builtins.elem "nvidia" profile.features);
    "layers.acceleration.disabled" = (builtins.elem "nvidia" profile.features);

    # ... rest of your commonSettings from firefox.nix ...
  };

  userChromeCss = '' 
    # ... your existing userChromeCss content ...
  '';

  # Helper function to write settings to user.js format
  mkUserJs = settings:
    let
      formatValue = v:
        if builtins.isBool v then if v then "true" else "false"
        else if builtins.isString v then ''"${v}"''
        else toString v;
      formatLine = name: value: ''user_pref("${name}", ${formatValue value});'';
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList formatLine settings);

  # Create wrapper script that sets up the profile and launches Zen
  zenWithConfig = pkgs.writeShellScriptBin "zen-browser" ''
    # Create profile directory if it doesn't exist
    PROFILE_DIR="''${HOME}/.zen-browser/default"
    mkdir -p "$PROFILE_DIR/chrome"

    # Write configurations
    echo "${mkUserJs commonSettings}" > "$PROFILE_DIR/user.js"
    echo "${userChromeCss}" > "$PROFILE_DIR/chrome/userChrome.css"

    # Launch Zen Browser with this profile
    exec ${pkgs.appimage-run}/bin/appimage-run ${src} --profile "$PROFILE_DIR" "$@"
  '';

in {
  options = {
    bzv.zen-browser.enable = mkEnableOption "Enable zen browser app image";
  };

  config = mkIf config.bzv.zen-browser.enable {
    # Install the wrapped Zen Browser
    home.packages = [ zenWithConfig ];

    # Create desktop entry
    xdg.desktopEntries = {
      ZenBrowser = {
        name = "Zen Browser";
        genericName = "Zen";
        exec = "${zenWithConfig}/bin/zen-browser";
        terminal = false;
        icon = logoPath;
      };
    };

    # Add Firefox-related environment variables
    programs.zsh.envExtra = mkIf config.programs.zsh.enable ''
      export MOZ_ENABLE_WAYLAND=1
      export MOZ_USE_XINPUT2=1
    '';
  };
} 