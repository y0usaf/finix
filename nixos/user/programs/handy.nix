{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  handy-base = flakeInputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

    # Send SIGUSR2 to toggle recording
    usr.files.".config/niri/config.kdl".value.binds.${config.user.programs.handy.keybind} = {
      spawn = ["pkill" "-SIGUSR2" "handy"];
    };
  };
}
