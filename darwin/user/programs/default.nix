{pkgs, ...}: {
  imports = [
    ./browsers
  ];

  home-manager.users.y0usaf = {
    home.packages = with pkgs; [
      tailscale
    ];
  };
}
