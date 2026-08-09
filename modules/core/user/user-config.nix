# Shared user options + NixOS-side user/sudo config. Imported by both hosts:
# desktop via the recursive walk (shimmed), server explicitly (shimmed). The
# finix-native side of user setup lives in hosts/*/finix/ (compat-import drops
# users.*/security.*, so only the `user.*` options survive here on finix).
{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "y0usaf";
        description = "Primary username for the system";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
        default = "/home/${config.user.name}";
        description = "Home directory path for the user";
      };
    };
  };

  config = {
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

    users.users."${config.user.name}" = {
      isNormalUser = true;
      # zsh is the only interactive shell module (modules/shell/zsh). finix is
      # the live system on both hosts and sets its own copy of this in
      # modules/finix/common.nix (compat-import drops users.*), so keep the two
      # in sync.
      shell = pkgs.zsh;
      home = toString config.user.homeDirectory;
      ignoreShellProgramCheck = true;
      extraGroups = ["wheel" "networkmanager" "docker"];
    };

    security.sudo.extraRules = [
      {
        users = [config.user.name];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
