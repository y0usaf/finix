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
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    };
  };
}
