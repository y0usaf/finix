# Pure literals (import/++ only, no lib/pkgs/config) — same contract as the
# desktop module, which finix replays as bind mounts. Shared entries live in
# ../common/persist.nix.
_: let
  common = import ../common/persist.nix;
in {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories =
      common.systemDirectories
      ++ [
        # Services
        "/var/lib/postgresql"
        "/var/lib/forgejo"
        "/var/lib/private" # n8n, blocky (systemd DynamicUser dirs)
        "/var/lib/btrbk"
      ];
    files = common.systemFiles;
    users.y0usaf = {
      directories =
        common.userDirectories
        ++ [
          ".hermes"
          ".config/claude"
        ];
      files = common.userFiles;
    };
  };
}
