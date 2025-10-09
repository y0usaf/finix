{
  config,
  lib,
  ...
}: {
  imports = [
    ./fetch-widget.nix
    ./bar-overlay.nix
  ];

  # Legacy compatibility - enable bar-overlay by default when old ags.enable is used
  config = lib.mkIf (config.user.ui.ags.enable or false) {
    user.ui.ags.bar-overlay.enable = lib.mkDefault true;
  };

  options.user.ui.ags = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 (defaults to bar-overlay)";
    };
  };
}
