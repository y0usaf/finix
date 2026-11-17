{pkgs, ...}: {
  user.persist.directories = [
    ".local/share/com.vercel.cli"
    ".local/share/com.vercel.token"
  ];
  # The wrapper each of these starts is the same package the box's guest installs (pkgs/vercel-account-router.nix),
  # so a boxed bot's vercel-work reads the host's work login and answers as it did on the host.
  environment.systemPackages = [(import ../../../../pkgs/vercel-account-router.nix {inherit pkgs;})];
}
