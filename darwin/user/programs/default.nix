{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./browsers
  ];

  home-manager.users.${config.user.name} = {
    home.packages = with pkgs; [
      tailscale
    ];
  };
}
