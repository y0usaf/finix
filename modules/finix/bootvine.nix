{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  cfg = config.finix.bootScreen;

  mkFinit = {
    plymouthSupport ? false,
    plymouth ? pkgs.plymouth,
    udevSupport ? false,
  }: let
    base = pkgs.finit.override {
      inherit plymouthSupport plymouth udevSupport;
    };
  in
    base.overrideAttrs (old: {
      configureFlags = (old.configureFlags or []) ++ ["--enable-kernel-cmdline"];
    });

  finit = mkFinit {} // {override = mkFinit;};
in {
  options.finix.bootScreen = {
    enable = lib.mkEnableOption "a live tree of finit services on the boot console";

    package = lib.mkOption {
      type = lib.types.package;
      inherit (inputPackages.bootvine) default;
      description = "The boot screen program.";
    };

    tty = lib.mkOption {
      type = lib.types.str;
      default = "/dev/tty12";
      description = "Virtual terminal the screen is drawn on, so the login prompts on tty1-tty6 stay free.";
    };
  };

  config = lib.mkIf cfg.enable {
    finit.package = finit;

    boot.kernelParams = [
      "quiet"
      "finit.status=off"
    ];

    finit.services.boot-screen = {
      description = "live tree of finit services";
      runlevel = "S0123456";
      command = "${lib.getExe cfg.package} --tty=${cfg.tty}";
      restart = 0;
    };
  };
}
