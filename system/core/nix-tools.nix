{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      alejandra
      statix
      deadnix
    ];
  };
}
