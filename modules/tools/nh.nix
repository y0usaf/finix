{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  nhOpts = config.user.tools.nh;
in {
  options.user.tools.nh = {
    enable = lib.mkEnableOption "nh (Nix Helper) shell integration";
    flake = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.singleLineStr lib.types.path);
      default = null;
      description = ''
        The path that will be used for the NH_FLAKE environment variable.
        NH_FLAKE is used by nh as the default flake for performing actions,
        like 'nh os switch'. If not set, nh will look for a flake in the current
        directory or prompt for the flake path.
      '';
    };
  };
  config = lib.mkIf nhOpts.enable {
    environment = {
      systemPackages = [
        flakeInputs.nh.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];
      sessionVariables.NH_FLAKE = toString (
        if nhOpts.flake != null
        then nhOpts.flake
        else config.user.paths.flake.path
      );
    };
    user.shell.rcExtra = lib.mkAfter ''
      nhs() {
        clear
        local update=""
        local dry=""
        local OPTIND
        while getopts "du" opt; do
          case $opt in
            d) dry="--dry" ;;
            u) update="--update" ;;
            *) echo "Invalid option: -$OPTARG" >&2 ;;
          esac
        done
        shift $((OPTIND - 1))
        # GC_DONT_GC: skip Boehm GC during eval (~35% less eval CPU,
        # peak RSS ~4-5GB). Remove if eval OOMs on low-memory hosts.
        GC_DONT_GC=1 nh os switch $update $dry "$@"
      }
      alias nhd="nhs -d"
      alias nhu="nhs -u"
      alias nhud="nhs -ud"
      alias nhc="nh clean all"
    '';
  };
}
