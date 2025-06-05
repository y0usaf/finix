###############################################################################
# NH (Nix Helper) Tool Module (Hjem Version)
# Provides shell integration and aliases for the NH flake helper
# - Custom nhs() function with option parsing
# - Convenient rebuild aliases
# Note: Core NH configuration (cleaning, flake path) handled by NixOS system module
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.tools.nh;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.tools.nh = {
    enable = lib.mkEnableOption "nh (Nix Helper) shell integration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      nh
    ];

    ###########################################################################
    # Shell Integration
    ###########################################################################
    files.".zshrc".text = lib.mkAfter ''
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