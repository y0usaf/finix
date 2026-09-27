{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
  ];
}
