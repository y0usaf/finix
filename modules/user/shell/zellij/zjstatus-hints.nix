{
  config,
  lib,
  flakeInputs,
  ...
}: let
  cfg = config.user.shell.zellij;
  zjstatusHintsPackage = flakeInputs.zjstatus-hints.packages.${config.nixpkgs.system}.default;
in {
  options.user.shell.zellij.zjstatusHints = {
    enable = lib.mkEnableOption "zjstatus-hints keybinding hints plugin";

    pipeName = lib.mkOption {
      type = lib.types.str;
      default = "zjstatus_hints";
      description = "Named pipe for communication between zjstatus and zjstatus-hints";
    };

    maxLength = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Maximum length of hints (0 = no limit)";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.zjstatus.enable && cfg.zjstatusHints.enable) {
    usr.files.".config/zellij/plugins/zjstatus-hints.wasm" = {
      clobber = true;
      source = "${zjstatusHintsPackage}/bin/zjstatus-hints.wasm";
    };
  };
}
