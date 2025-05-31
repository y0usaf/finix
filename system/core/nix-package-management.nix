# This module configures Nix package management.
{
  pkgs,
  hostSystem,
  ...
}: {
  config = {
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        experimental-features = ["nix-command" "flakes"];
        sandbox = true;
        trusted-users = ["root" hostSystem.cfg.system.username];
        builders-use-substitutes = true;
        fallback = true;

        substituters = [
          "https://cache.nixos.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      };
      extraOptions = "";
    };
  };
}
