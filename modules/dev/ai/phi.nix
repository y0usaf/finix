{inputPackages, ...}: {
  user.persist.directories = [
    ".config/phi"
    ".local/share/phi"
    ".phi"
  ];
  environment.systemPackages = [inputPackages.phi.default];
}
