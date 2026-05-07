{
  lib,
  pkgs,
  ...
}: let
  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);
in {
  user = {
    name = "y0usaf";
    homeDirectory = "/home/y0usaf";
  };

  users.users.y0usaf = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = ["wheel" "networkmanager" "docker"];
    home = "/home/y0usaf";
    ignoreShellProgramCheck = true;
    hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
    openssh.authorizedKeys.keys = [
      (readKey ../../../hosts/y0usaf-desktop/user-ssh.pub)
      (readKey ../../../hosts/android-phone/user-ssh.pub)
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["y0usaf"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
