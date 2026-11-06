{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.devin-cli];

  user.files = {
    ".config/devin/AGENTS.md".text =
      config.user.dev.prompts.shared;
    ".config/devin/config.json" = {
      type = "merge";
      format = "json";
      clobber = true;
      value.attribution = false;
    };
  };

  environment.variables.DEVIN_PERMISSION_MODE = "dangerous";
}
