{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.services.formatNix = {
    enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";
    watchDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.user.paths.flake.path;
      description = "Directory to watch for Nix file changes";
    };
  };

  config = lib.mkIf config.user.services.formatNix.enable {
    environment.systemPackages = [pkgs.alejandra pkgs.inotify-tools];
  };
}
