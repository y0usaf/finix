{pkgs, ...}: {
  config = {
    environment.systemPackages = [
      pkgs.alejandra
      pkgs.statix
      pkgs.deadnix
    ];
  };
}
