{lib, ...}: {
  environment.etc."ssh/authorized_keys.d/y0usaf".text = ''
    ${lib.removeSuffix "\n" (builtins.readFile ../y0usaf-desktop/user-ssh.pub)}
    ${lib.removeSuffix "\n" (builtins.readFile ../y0usaf-framework/user-ssh.pub)}
    ${lib.removeSuffix "\n" (builtins.readFile ../y0usaf-server/user-ssh.pub)}
    ${lib.removeSuffix "\n" (builtins.readFile ../android-phone/user-ssh.pub)}
  '';
}
