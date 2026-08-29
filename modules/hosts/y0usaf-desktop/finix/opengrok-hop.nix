# opengrok hop shim: Vercel AI Gateway bearer injection for Grok Bot.
# Lives in the finix flake (finit service, loopback only); the package comes
# from the grok-bot-opengrok flake input. The key file is root-owned 0400 at
# /var/lib/opengrok/gateway.env (atticd token.env pattern), so the key never
# lands in the store or in model-bindings.json.
{ config, lib, pkgs, flakeInputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
  pkg = flakeInputs.grok-bot-opengrok.packages.${system}.grok-bot-glm-gateway;
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";
  keyEnv = /var/lib/opengrok/gateway.env;
in {
  environment.systemPackages = [ pkg ];

  finit.services.opengrok-vercel-gateway-hop = {
    description = "opengrok hop shim -> Vercel AI Gateway (GLM 5.3 Flash)";
    user = userName;
    environment = {
      HOME = user.home;
      XDG_RUNTIME_DIR = runtimeDir;
      HERMES_HOP_PORT = "18791";
      HERMES_HOP_UPSTREAM = "https://ai-gateway.vercel.sh";
    };
    command = pkgs.writeShellScript "opengrok-gateway-hop-run" ''
      set -a
      . ${keyEnv}
      set +a
      exec ${pkgs.python3}/bin/python3 ${pkg}/share/opengrok/tools/hop-server.py
    '';
    conditions = ["net/lo/up"];
    log = true;
  };
}
