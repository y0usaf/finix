{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.tools.nh.enable = lib.mkEnableOption "nh (Nix Helper) shell integration";

  config = lib.mkIf config.user.tools.nh.enable {
    environment = {
      systemPackages = [
        flakeInputs.nh.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];
      variables.NH_FLAKE = config.user.paths.flake.path;
    };
    user.shell.rcExtra = lib.mkAfter ''
      nhs() {
        clear
        local update=""
        local dry=""
        while [ $# -gt 0 ]; do
          case $1 in
            -d|--dry) dry="--dry" ;;
            -u|--update) update="--update" ;;
            -du|-ud) dry="--dry"; update="--update" ;;
            *) break ;;
          esac
          shift
        done
        GC_DONT_GC=1 nh os switch $update $dry "$@"
      }
      alias nhd="nhs -d"
      alias nhu="nhs -u"
      alias nhud="nhs -ud"
      alias nhc="nh clean all"
    '';
  };
}
