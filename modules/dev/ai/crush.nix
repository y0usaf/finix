{
  config,
  pkgs,
  ...
}: {
  user.persist.directories = [
    ".config/crush"
    ".crush"
    ".local/share/crush"
  ];
  environment.systemPackages = [pkgs.crush];

  user.files.".config/crush/CRUSH.md".text =
    config.user.dev.prompts.shared;
}
