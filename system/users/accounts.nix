{
  config,
  pkgs,
  userConfigs,
  lib,
  ...
}: {
  config = {
    users.users = lib.mkMerge [
      # Create users for each configured user
      (lib.genAttrs config.hostSystem.users (username: let
        userConfig = userConfigs.${username};
        systemConfig = userConfig.system or {};
      in {
        isNormalUser = systemConfig.isNormalUser or true;
        shell = pkgs.${systemConfig.shell or "zsh"};
        extraGroups = systemConfig.extraGroups or ["networkmanager" "video" "audio"];
        home = systemConfig.homeDirectory or "/home/${username}";
        password = systemConfig.password or null;
        ignoreShellProgramCheck = true;
      }))
    ];
  };
}
