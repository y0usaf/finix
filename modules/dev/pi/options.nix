{
  config,
  lib,
  ...
}: let
  mkInternalStr = description:
    lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "";
      inherit description;
    };

  mkNullStr = description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      inherit description;
    };
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";

    rtk.enable = lib.mkEnableOption "pi-rtk extension and rtk binary";

    compactness = {
      tools = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Render collapsed tool calls as compact one-line summaries with pi-compact.";
      };

      user = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Render user inputs as compact one-line summaries with pi-compact.";
      };

      toolColour = mkNullStr "Optional hex background colour for compact tool rows.";
      userColour = mkNullStr "Optional hex background colour for compact user rows.";
    };

    extensionSettings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
      description = "Extension-specific settings written to extension-settings.json.";
    };

    # Documentation paths (set by extensions.nix, read by prompts.nix)
    readmePath = mkInternalStr "Path to the pi README.";
    docsPath = mkInternalStr "Path to the pi docs directory.";
    examplesPath = mkInternalStr "Path to the pi examples directory.";
  };
}
