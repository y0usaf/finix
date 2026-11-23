{pkgs, ...}: {
  user.persist.directories = [
    ".local/share/com.vercel.cli"
    ".local/share/com.vercel.token"
  ];
  environment.systemPackages = [(import ../../../../pkgs/vercel-account-router.nix {inherit pkgs;})];
}
