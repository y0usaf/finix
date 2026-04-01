{pkgs, ...}: {
  user = {
    name = "guest";
    homeDirectory = "/home/guest";
  };

  users.users.guest = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "video" "audio"];
    home = "/home/guest";
    ignoreShellProgramCheck = true;
  };
}
