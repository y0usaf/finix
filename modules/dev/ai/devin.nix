{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.devin-cli
  ];

  manzil.users."${config.user.name}".files = {
    ".config/devin/AGENTS.md".text =
      config.user.dev.prompts.shared;
    ".config/devin/config.json" = {
      type = "merge";
      format = "json";
      clobber = true;
      value = {
        attribution = false;
      };
    };
  };

  environment.variables.DEVIN_PERMISSION_MODE = "dangerous";
}
