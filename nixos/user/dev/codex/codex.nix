{
  config,
  lib,
  ...
}: {
  options.user.dev.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration and instructions";

    model = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.4";
      description = "Codex model to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Codex CLI config.toml setting overrides.";
    };

    skills =
      lib.mapAttrs (skillName: _: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install the `${skillName}` Codex skill.";
        };
      })
      (import ./data).skills;
  };

  config = lib.mkIf config.user.dev.codex.enable {};
}
