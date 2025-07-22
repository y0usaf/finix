{
  config,
  pkgs,
  ...
}: {
  config = {
    users.users.${config.hostSystem.username} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
        "gamemode"
      ];
      ignoreShellProgramCheck = true;
    };
  };
}
