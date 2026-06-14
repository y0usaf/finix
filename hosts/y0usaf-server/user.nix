{
  config,
  lib,
  ...
}: let
  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);
in {
  users.users."${config.user.name}" = {
    hashedPasswordFile = "/persist/secrets/password-hashes/y0usaf";
    openssh.authorizedKeys.keys = [
      (readKey ../y0usaf-desktop/user-ssh.pub)
      (readKey ../android-phone/user-ssh.pub)
    ];
  };
}
