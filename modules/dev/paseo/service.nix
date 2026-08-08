# Paseo daemon as a finit service (desktop host, real user).
#
# Runs paseo-server (the foreground supervisor entrypoint) as the real
# user. The daemon spawns coding-agent CLIs (claude, codex, opencode,
# pi, ...), which sit in environment.systemPackages -> /run/current-system/
# sw/bin, so the service PATH includes that dir plus the user's profile
# bins (mirroring the NixOS module's inheritUserEnvironment). Relay on by
# default: phone reaches the daemon through app.paseo.sh regardless of LAN.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.paseo;
  system = pkgs.stdenv.hostPlatform.system;
  paseo = flakeInputs.paseo.packages."${system}".default;
  home = config.user.homeDirectory;
  homePaseo = "${home}/${cfg.dataDir}";
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ paseo ];

    finit.services.paseo = {
      description = "Paseo - self-hosted daemon for AI coding agents";
      user = config.user.name;
      group = config.user.name;
      command = "${pkgs.writeShellScript "paseo-server-start" ''
        set -eu
        export PATH=${lib.makeBinPath [
          "/run/current-system/sw/bin"
          "/run/wrappers/bin"
          "${home}/.nix-profile/bin"
          "${home}/.local/state/nix/profile/bin"
          "/nix/var/nix/profiles/default/bin"
        ]}:$PATH
        exec ${paseo}/bin/paseo-server ${lib.optionalString (!cfg.relay.enable) "--no-relay"}
      ''}";
      environment = {
        HOME = home;
        PASEO_HOME = homePaseo;
        PASEO_LISTEN = "${cfg.listenAddress}:${toString cfg.port}";
      } // cfg.environment;
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
