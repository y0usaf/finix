{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.nh;
in {
  options.home.tools.nh = {
    enable = lib.mkEnableOption "nh (Nix Helper) shell integration";
    flake = lib.mkOption {
      type = with lib.types; nullOr (either singleLineStr path);
      default = null;
      description = ''
        The path that will be used for the NH_FLAKE environment variable.
        NH_FLAKE is used by nh as the default flake for performing actions,
        like 'nh os switch'. If not set, nh will look for a flake in the current
        directory or prompt for the flake path.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nh
    ];
    usr = {
      files = {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            export NH_FLAKE="${config.user.nixosConfigDirectory}"
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
              shift $((OPTIND-1))
              nh os switch $update $dry "$@"
            }
            alias nhd="nhs -d"
            alias nhu="nhs -u"
            alias nhud="nhs -ud"
            alias nhc="nh clean all"
          '';
          clobber = true;
        };
      };
    };
  };
}
