{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/cmus"
  ];
  environment.systemPackages = [pkgs.cmus];
  manzil.users."${config.user.name}".files.".config/cmus/rc".text = ''
    colorscheme wallust-auto

  '';
}
