{
  pkgs,
  inputs,
  config,
  ...
}: {
  config = {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = pkgs.hyprland; # Use nixpkgs version for npins compatibility
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
  };
}
