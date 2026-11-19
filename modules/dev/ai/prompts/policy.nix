{
  config,
  lib,
  ...
}: {
  options.user.dev.prompts = {
    host = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Facts about this host, each set by the module that owns it.";
    };
    shared = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Empty global harness append prompt (rules and host facts live in ~/AGENTS.md).";
    };
    portable = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Empty portable harness append prompt (rules live in AGENTS.md).";
    };
  };

  config.user.dev.prompts = {
    host = lib.mkOrder 400 (
      ["Init: finit (`initctl`), sysklogd (`/var/log`); no systemd/`systemctl`/`journalctl`/`loginctl`."]
      ++ lib.optional ((config.fileSystems."/".fsType or null) == "tmpfs") "`/` is tmpfs (ephemeral across reboot outside persistent mounts)."
    );
    portable = "";
    shared = "";
  };
}
