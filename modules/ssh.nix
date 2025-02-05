#===============================================================================
#                       🔐 SSH Configuration 🔐
#===============================================================================
# 🔑 Key management
# 🌐 Host settings
# 🔧 Connection params
# 🛡️ Security config
#===============================================================================
{
  config,
  pkgs,
  profile,
  ...
}: {
  programs.ssh = {
    enable = true;

    extraConfig = ''
      SetEnv TERM=xterm-256color
    '';

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/Tokens/id_rsa_y0usaf";
      };
    };
  };

  services.ssh-agent.enable = true;
}
