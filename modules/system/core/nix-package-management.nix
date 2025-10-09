{
  config,
  lib,
  pkgs,
  ...
}: {
  options.trustedUsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Additional trusted Nix users";
  };

  config = {
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        experimental-features = ["nix-command" "flakes"];
        sandbox = true;
        trusted-users = ["root"] ++ config.trustedUsers;
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
