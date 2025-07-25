# User configuration abstraction
# Provides consistent user and path management across all modules
{
  lib,
  config,
  ...
}: {
  options = {
    # User configuration options
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Primary username for the system";
        example = "alice";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
        description = "Home directory path for the user";
        example = "/home/alice";
      };

      configDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.config";
        description = "XDG config directory path";
      };

      dataDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.local/share";
        description = "XDG data directory path";
      };

      stateDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.local/state";
        description = "XDG state directory path";
      };

      cacheDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.cache";
        description = "XDG cache directory path";
      };

      # Project-specific paths
      nixosConfigDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/nixos";
        description = "NixOS configuration directory";
      };

      tokensDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/Tokens";
        description = "Directory containing API tokens and secrets";
      };
    };
  };

  config = {
    # Assertions to validate user configuration
    assertions = [
      {
        assertion = config.user.name != "";
        message = "user.name must be set to a non-empty string";
      }
      {
        assertion = lib.hasPrefix "/" (toString config.user.homeDirectory);
        message = "user.homeDirectory must be an absolute path";
      }
    ];
  };
}
