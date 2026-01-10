{
  config,
  pkgs,
  lib,
  flakeInputs,
  ...
}: let
  handy-base = flakeInputs.handy.packages.${pkgs.system}.default;
  handy = pkgs.writeShellScriptBin "handy" ''
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
    exec ${handy-base}/bin/handy "$@"
  '';
in {
  options.user.programs.handy = {
    enable = lib.mkEnableOption "Handy speech-to-text";
    keybind = lib.mkOption {
      type = lib.types.str;
      default = "Alt+V";
      description = "Niri keybind to toggle Handy recording";
    };
  };

  config = lib.mkIf config.user.programs.handy.enable {
    environment.systemPackages = [
      handy
      pkgs.wtype # Ensure wtype is available for Wayland text injection
    ];
  };
}
