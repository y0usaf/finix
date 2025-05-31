#═══════════════════════════ 🔧 NH MODULE 🔧 ═══════════════════════════#
# Core module for the NH flake helper
# - Always enabled as a core tool
# - Configures automatic cleaning
# - Provides Pacman-like aliases for nh commands
#═════════════════════════════════════════════════════════════════════#
{hostHome, ...}: {
  #===========================================================================
  # NH Configuration
  #===========================================================================
  programs.nh = {
    enable = true;
    flake = hostHome.cfg.directories.flake.path;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };

  # Add nh shell function for better argument handling
  programs.zsh.initContent = ''
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
  '';
}
