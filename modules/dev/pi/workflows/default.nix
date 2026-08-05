{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.pi.enable {
    manzil.users."${config.user.name}".files = {
      ".pi/workflows/goal-loop.json".source = ./goal-loop.json;
    };
  };
}
