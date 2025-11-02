{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  options.user.shell.zellij.zjstatusHints = {
    enable = lib.mkEnableOption "zjstatus-hints keybinding hints plugin";

    pipeName = lib.mkOption {
      type = lib.types.str;
      default = "zjstatus_hints";
    };

    maxLength = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };
  };

  config = lib.mkIf (config.user.shell.zellij.enable && config.user.shell.zellij.zjstatus.enable && config.user.shell.zellij.zjstatusHints.enable) {
    home-manager.users.y0usaf.home.file.".config/zellij/plugins/zjstatus-hints.wasm" = {
      source = "${inputs.zjstatus-hints.packages.${pkgs.system}.default}/bin/zjstatus-hints.wasm";
    };
  };
}
