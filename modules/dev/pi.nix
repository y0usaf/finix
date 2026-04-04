{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  piPkg = flakeInputs."pi-mono".packages."${system}".default;
  piAgentsPkg = flakeInputs."pi-agents".packages."${system}".default;
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";
  };

  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      piPkg
    ];

    # Expose the local pi-agents package path for co-development without
    # auto-enabling it in pi. Use:
    #   pi install "$PI_AGENTS_PACKAGE"
    #   pi -e "$PI_AGENTS_PACKAGE/index.ts"
    environment.variables.PI_AGENTS_PACKAGE = "${piAgentsPkg}";
  };
}
