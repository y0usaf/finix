{config, ...}: {
  manzil.users."${config.user.name}".files = {
    ".pi/workflows/goal-loop.json".source = ./goal-loop.json;
  };
}
