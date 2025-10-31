{
  config,
  lib,
  ...
}: {
  options = {
    var-cache = lib.mkEnableOption "Use /var/cache/nix for nix cache directory";
  };

  config = lib.mkIf config.var-cache {
    nix.settings = {
      max-jobs = "auto";
      cores = 0;

      auto-optimise-store = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    systemd.tmpfiles.rules = [
      "d /var/cache/nix 0755 root root -"
    ];
  };
}
