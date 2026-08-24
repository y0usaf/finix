{
  config,
  lib,
  ...
}: {
  services.nix-daemon = {
    enable = true;
    settings.trusted-users = lib.mkForce ["root" config.user.name];
  };

  finit.tasks.remount-nix-store.enable = false;
}
