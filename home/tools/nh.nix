###############################################################################
# NH (Nix Helper) Tool Module (Nix-Maid Version)
# Provides shell integration and aliases for the NH flake helper
# - Custom nhs() function with option parsing
# - Convenient rebuild aliases
# - Flake directory configuration via NH_FLAKE environment variable
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.nh;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
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

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      nh
    ];

    ###########################################################################
    # Shell Integration
    ###########################################################################
    users.users.y0usaf.maid.file.home.".config/zsh/.zshrc".text = lib.mkAfter ''
      # Set NH_FLAKE environment variable for NH (Nix Helper)
      export NH_FLAKE="/home/y0usaf/nixos"

      # NixOS rebuild/switch function with proper argument parsing
      nhs() {
        clear
        local update=""
        local dry=""
        local OPTIND

        # Parse options using getopts
        while getopts "du" opt; do
          case $opt in
            d) dry="--dry" ;;
            u) update="--update" ;;
            *) echo "Invalid option: -$OPTARG" >&2 ;;
          esac
        done

        # Remove the parsed options from the arguments list
        shift $((OPTIND-1))

        # Execute nh command with appropriate flags and pass any remaining arguments
        nh os switch $update $dry "$@"
      }

      # NH convenience aliases
      alias nhd="nhs -d"        # Dry run
      alias nhu="nhs -u"        # Update flake inputs
      alias nhud="nhs -ud"      # Update + dry run
      alias nhc="nh clean all"  # Clean old generations
    '';
  };
}
