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
      variables.NH_FLAKE = toString (
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
        # Parse -d/-u (and their bundles) by hand: getopts consumes a long
        # option character by character, so `nhs --update` set BOTH --update
        # and --dry (the d in "update"), and every other long nh flag
        # containing a d or u was eaten the same way. Stop at the first
        # argument that is not one of our flags so nh's own flags, a flake
        # path or a hostname pass through untouched.
        while [ $# -gt 0 ]; do
          case $1 in
            -d|--dry) dry="--dry" ;;
            -u|--update) update="--update" ;;
            -du|-ud) dry="--dry"; update="--update" ;;
            *) break ;;
          esac
          shift
        done
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
