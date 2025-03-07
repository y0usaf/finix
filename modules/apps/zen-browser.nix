{
  lib,
  config,
  pkgs,
  profile,
  ...
}:
with lib; let
  src = builtins.fetchurl {
    url = "https://github.com/zen-browser/desktop/releases/latest/download/zen-x86_64.AppImage";
    sha256 = "119gxhbwabl2zzxnm4l0vd18945mk2l0k12g5rf9x8v9lzsm7knn";
  };

  # Basic settings for Zen Browser
  commonSettings = {
    # Enable userChrome customizations
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Nvidia-specific settings
    "gfx.webrender.all" = !(builtins.elem "nvidia" profile.features);
    "media.hardware-video-decoding.enabled" = !(builtins.elem "nvidia" profile.features);
    "media.ffmpeg.vaapi.enabled" = !(builtins.elem "nvidia" profile.features);
    "layers.acceleration.disabled" = builtins.elem "nvidia" profile.features;
  };

  # Helper function to write settings to user.js format
  mkUserJs = settings: let
    formatValue = v:
      if builtins.isBool v
      then
        if v
        then "true"
        else "false"
      else if builtins.isString v
      then ''"${v}"''
      else toString v;
    formatLine = name: value: ''user_pref("${name}", ${formatValue value});'';
  in
    lib.concatStringsSep "\n" (lib.mapAttrsToList formatLine settings);

  # Create wrapper script that sets up the profile and launches Zen
  zenWithConfig = pkgs.writeShellScriptBin "zen-browser" ''
    # Create profile directory if it doesn't exist
    PROFILE_DIR="''${HOME}/.zen-browser/default"
    mkdir -p "$PROFILE_DIR"

    # Write configurations
    echo "${mkUserJs commonSettings}" > "$PROFILE_DIR/user.js"

    # Launch Zen Browser with this profile
    exec ${pkgs.appimage-run}/bin/appimage-run ${src} --profile "$PROFILE_DIR" "$@"
  '';
in {
  config = mkIf (builtins.elem "zen-browser" profile.features) {
    # Install the wrapped Zen Browser
    home.packages = [
      zenWithConfig
      pkgs.qt6Packages.qtbase
      pkgs.qt6Packages.qtwayland
    ];

    # Create desktop entry
    xdg.desktopEntries.ZenBrowser = {
      name = "Zen Browser";
      genericName = "Zen";
      exec = "${zenWithConfig}/bin/zen-browser";
      terminal = false;
      categories = ["Network" "WebBrowser"];
    };

    # Add Firefox-related environment variables
    programs.zsh.envExtra = mkIf config.programs.zsh.enable ''
      export MOZ_ENABLE_WAYLAND=1
      export MOZ_USE_XINPUT2=1
    '';
  };
}
