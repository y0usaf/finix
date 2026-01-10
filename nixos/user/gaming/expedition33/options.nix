{lib, ...}: {
  options.user.gaming.expedition33.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Clair Obscur: Expedition 33 configuration files";
  };
}
