{
  config,
  lib,
  ...
}: let
  inherit (lib) attrByPath mkDefault mkEnableOption mkIf;
in {
  options.user.dev.codex = {
    enable = mkEnableOption "Codex CLI YOLO-mode config.toml";
  };

  config = mkIf (attrByPath ["user" "programs" "codex-desktop" "enable"] false config
    && attrByPath ["user" "programs" "codex-desktop" "yoloMode"] false config) {
    user.dev.codex.enable = mkDefault true;
  };
}
