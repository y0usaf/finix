{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/crush"
    ".crush"
    ".local/share/crush"
  ];
  environment.systemPackages = [
    pkgs.crush
  ];

  manzil.users."${config.user.name}".files.".config/crush/CRUSH.md".text =
    config.user.dev.prompts.shared;
}
