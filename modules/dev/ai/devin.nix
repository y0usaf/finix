{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.devin-cli.overrideAttrs (old: rec {
      version = "3000.11.234";
      src = pkgs.fetchurl {
        url = "https://static.devin.ai/cli/${version}/devin-${version}-x86_64-unknown-linux.tar.gz";
        hash = "sha256-IBNwzd0pJClOPKa0b9js5JtXY5U7ZEod2CP85UkMtBo=";
      };
    }))
  ];

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
