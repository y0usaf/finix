{lib, ...}: {
  options.user.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration using hjem";
    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Scaling factor for GTK applications (e.g., 1.0, 1.25, 1.5, 2.0)";
    };
  };
}
