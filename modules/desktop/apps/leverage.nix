{inputPackages, ...}: {
  user.persist.directories = [
    ".config/Leverage"
    ".config/leverage"
  ];
  environment.systemPackages = [inputPackages.leverage.default];
}
