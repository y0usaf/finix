{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.autolith;
in {
  options.user.dev.autolith = {
    enable = lib.mkEnableOption "Autolith live Common Lisp AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakeInputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "Autolith package, including its matching Lisp runtime.";
    };

    initLisp = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Common Lisp loaded in package AUTOLITH before provider requests.
        Nonempty content manages ~/.config/autolith/init.lisp through Manzil.
        Leave empty to manage that file interactively. Keep credentials out
        of this option; authenticate with `autolith auth` instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    manzil.users.${config.user.name}.files = lib.mkIf (cfg.initLisp != "") {
      ".config/autolith/init.lisp".text = cfg.initLisp;
    };

    # Preserve auth/preferences, conversations/private images, and recovery
    # state across home resets. The XDG cache is disposable.
    finix.persistence.allowlist.users.${config.user.name}.directories =
      map
      (directory: {
        inherit directory;
        mode = "0700";
      })
      [
        ".config/autolith"
        ".local/share/autolith"
        ".local/state/autolith"
      ];
  };
}
