{pkgs, ...}: {
  user.persist.directories = [
    ".local/share/cargo"
    ".local/share/rustup"
  ];
  environment.systemPackages = [
    pkgs.crane
    pkgs.rustup
    pkgs.openssl
  ];
}
