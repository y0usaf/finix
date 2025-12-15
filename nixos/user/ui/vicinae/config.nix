{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.ui.vicinae.enable {
    environment.systemPackages = [pkgs.vicinae];

    # Note: Wallust will generate the wallust-auto.toml theme based on colorscheme
    # This happens via the wallust template system when vicinae is enabled
  };
}
