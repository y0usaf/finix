{config, ...}: {
  home-manager.users."${config.user.name}".programs.git = {
    enable = true;
    settings = {
      user = {
        name = "y0usaf";
        email = "OA99@Outlook.com";
      };
    };
  };
}
