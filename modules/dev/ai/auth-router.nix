{
  config,
  inputPackages,
  ...
}: let
  authRouter = inputPackages.auth-router.default;
  user = config.user.name;
  home = config.users.users.${user}.home;
  inherit (config.user) runtimeDir;
  socket = "${runtimeDir}/auth-router.sock";
  restrictedSocket = "${runtimeDir}/auth-router-restricted.sock";
in {
  user.persist.directories = [".local/state/crest-auth"];
  finix.persistence.homeServices = ["auth-router"];
  environment = {
    variables.AUTH_ROUTER_SOCKET = socket;
    systemPackages = [authRouter];
  };
  finit.services.auth-router = {
    description = "auth-router credential and routing daemon";
    inherit user;
    group = "users";
    reload-signal = "none";
    respawn = true;
    log = true;
    conditions = ["task/tmpfiles-setup/success"];
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
      AUTH_ROUTER_STATE_DIR = "${home}/.local/state/crest-auth";
    };
    command = "${authRouter}/bin/auth-router daemon --socket ${socket} --restricted-socket ${restrictedSocket}";
  };
}
