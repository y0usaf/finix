# Shared user options. The NixOS-side assertions/users.users/security.sudo
# config was dropped by the compat shim (only the `user.*` options survive);
# finix sets its own copy of the shell/user setup in modules/finix/common.nix.
{
  config,
  lib,
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
}