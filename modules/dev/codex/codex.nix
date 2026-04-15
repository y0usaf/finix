{
  config,
  lib,
  ...
}: let
  inherit (lib) attrByPath mapAttrs mkDefault mkEnableOption mkForce mkIf mkMerge mkOption types;
  aiSkills = {
    agent-slack = import ../skills/agent-slack.nix {moduleMode = false;};
    gh = import ../skills/gh.nix {moduleMode = false;};
    linear-cli = import ../skills/linear-cli.nix {moduleMode = false;};
  };

  codexDesktopYoloMode =
    attrByPath ["user" "programs" "codex-desktop" "enable"] false config
    && attrByPath ["user" "programs" "codex-desktop" "yoloMode"] false config;
in {
  options.user.dev.codex = {
    enable = mkEnableOption "Codex CLI configuration and instructions";

    model = mkOption {
      type = types.str;
      default = "gpt-5.4";
      description = "Codex model to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Codex CLI config.toml setting overrides.";
    };

    skills =
      mapAttrs (skillName: _: {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to install the `${skillName}` Codex skill.";
        };
      })
      aiSkills;
  };

  config = mkMerge [
    (mkIf config.user.dev.codex.enable {})
    (mkIf codexDesktopYoloMode {
      user.dev.codex = {
        enable = mkDefault true;
        settings = {
          approval_policy = mkForce "never";
          sandbox_mode = mkForce "danger-full-access";
        };
      };
    })
  ];
}
