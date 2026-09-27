{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.ffmpeg
    pkgs.vlc
  ];
}
