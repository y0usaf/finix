{
  config,
  lib,
  ...
}: let
  inherit (lib) attrByPath mapAttrs mkDefault mkEnableOption mkIf mkMerge mkOption types;
  inherit (config.user.dev) codex;
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

    providers."vercel-ai-gateway" = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Vercel AI Gateway provider for Codex.";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "https://ai-gateway.vercel.sh/v1";
        description = ''
          Vercel AI Gateway base URL for OpenAI-compatible Codex requests.
          This becomes `model_providers."vercel-ai-gateway".base_url`.
        '';
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
        description = ''
          Path (as a string, not a path literal) to a file containing the
          Vercel AI Gateway API key/token. Appends a nushell env.nu snippet
          that reads AI_GATEWAY_API_KEY from this file at shell startup.
        '';
      };

      wireApi = mkOption {
        type = types.str;
        default = "responses";
        description = ''
          Codex wire API for the Vercel AI Gateway provider. `responses`
          matches the documented OpenAI Responses API integration.
        '';
      };
    };

    skills =
      mapAttrs (skillName: _: {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to install the `${skillName}` Codex skill.";
        };
      })
      {
        agent-slack = import ../skills/agent-slack.nix {moduleMode = false;};
        gh = import ../skills/gh.nix {moduleMode = false;};
        linear-cli = import ../skills/linear-cli.nix {moduleMode = false;};
      };
  };

  config = mkMerge [
    (mkIf codex.enable {})
    (mkIf codex.providers."vercel-ai-gateway".enable {
      user.dev.codex.model = mkDefault "openai/gpt-5.4";
    })
    (mkIf (attrByPath ["user" "programs" "codex-desktop" "enable"] false config
      && attrByPath ["user" "programs" "codex-desktop" "yoloMode"] false config) {
      user.dev.codex = {
        enable = mkDefault true;
        settings = {
          approval_policy = "never";
          sandbox_mode = "danger-full-access";
        };
      };
    })
  ];
}
