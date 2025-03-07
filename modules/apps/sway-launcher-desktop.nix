{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      fzf
    ];

    home.activation.symlinkSwayLauncherDesktop = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create scripts directory
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.config/scripts"

      # Symlink the launcher script
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${config.home.homeDirectory}/nixos/pkg/scripts/sway-launcher-desktop.sh" "$HOME/.config/scripts/sway-launcher-desktop.sh"
    '';
  };
}
