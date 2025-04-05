#===============================================================================
# 🌍 Home Environment Configuration Module 🌍
# Configures environment variables and paths for the user environment
# - Session variables for various services and applications
# - Search paths for executables
# - Token management functions
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.core.env;

  # --- User Session Environment Variables ----------------------------------
  userSessionVars = {
    LIBSEAT_BACKEND = "logind";
    # Add other user session variables here
  };

  # --- Common token management function -----------------------------------
  tokenFunctionScript = ''
    # Token management function
    export_vars_from_files() {
        local dir_path=$1
        for file_path in "$dir_path"/*.txt; do
            if [[ -f $file_path ]]; then
                var_name=$(basename "$file_path" .txt)
                export $var_name=$(cat "$file_path")
            fi
        done
    }

    # Export tokens
    export_vars_from_files "${cfg.tokenDir}"
  '';
in {
  #===========================================================================
  # Module Options
  #===========================================================================
  options.modules.core.env = {
    enable = lib.mkEnableOption "home environment configuration";

    tokenDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/Tokens";
      description = "Directory containing token files to be loaded as environment variables";
    };
  };

  #===========================================================================
  # Module Configuration
  #===========================================================================
  config = lib.mkIf cfg.enable {
    #===========================================================================
    # Home Session Configuration
    #===========================================================================
    home = {
      # Apply session variables
      sessionVariables = lib.mkMerge [
        userSessionVars
      ];

      # Define additional executable search paths for the user's session
      sessionPath = [
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    #===========================================================================
    # Shell Environment Configuration
    #===========================================================================
    programs.zsh.envExtra = lib.mkIf config.programs.zsh.enable tokenFunctionScript;
  };
}
