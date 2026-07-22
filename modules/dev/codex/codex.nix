{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrByPath mapAttrs mkDefault mkEnableOption mkIf mkMerge mkOption optionals types;
  inherit (config.user.dev) codex;
in {
  options.user.dev.codex = {
    enable = mkEnableOption "Codex CLI configuration and instructions";

    model = mkOption {
      type = types.str;
      default = "gpt-5.6-sol";
      description = "Codex model to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Codex CLI config.toml setting overrides.";
    };

    providers = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            example = "Vercel AI Gateway";
            description = "Display name for the provider in config.toml.";
          };

          baseUrl = mkOption {
            type = types.str;
            example = "https://ai-gateway.vercel.sh/v1";
            description = ''
              OpenAI-compatible base URL. Becomes
              `model_providers.<name>.base_url` in config.toml.
            '';
          };

          envKey = mkOption {
            type = types.str;
            default = "${lib.toUpper (lib.replaceStrings ["-"] ["_"] name)}_API_KEY";
            defaultText = "<NAME>_API_KEY";
            description = ''
              Env var Codex reads the API key from
              (`model_providers.<name>.env_key`). The `codex-<name>` wrapper
              exports it for its own invocation when `apiKeyFile` is set.
            '';
          };

          apiKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
            description = ''
              Path (as a string, not a path literal) to a file containing the
              provider API key. Read at wrapper runtime and exported as
              `envKey` for that invocation only. Must be a string so the
              secret is not copied into the world-readable Nix store.
            '';
          };

          model = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "openai/gpt-5.4";
            description = ''
              Model the `codex-<name>` wrapper selects. `null` keeps the
              config.toml default (`user.dev.codex.model`).
            '';
          };
        };
      }));
      default = {};
      description = ''
        Named model providers. Every entry is declared inertly in
        config.toml's `model_providers` table and generates a `codex-<name>`
        wrapper that selects it per invocation. Plain `codex` uses
        `defaultProvider`, or ChatGPT login when that is null.
      '';
    };

    defaultProvider = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "vercel";
      description = ''
        Provider plain `codex` uses (sets top-level `model_provider` in
        config.toml). `null` leaves plain `codex` on ChatGPT login. The
        provider's `envKey` must be present in the session environment.
      '';
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
    (mkIf codex.enable {
      assertions = [
        {
          assertion = codex.defaultProvider == null || codex.providers ? "${codex.defaultProvider}";
          message = ''
            user.dev.codex.defaultProvider = "${toString codex.defaultProvider}"
            does not match any entry in user.dev.codex.providers.
          '';
        }
      ];

      environment.systemPackages =
        lib.mapAttrsToList (
          name: provider:
            pkgs.writeShellScriptBin "codex-${name}" (
              lib.optionalString (provider.apiKeyFile != null) ''
                export ${provider.envKey}="$(tr -d '[:space:]' < ${lib.escapeShellArg provider.apiKeyFile})"
              ''
              + ''
                exec codex ${lib.escapeShellArgs (["-c" "model_provider=\"${name}\""]
                    ++ optionals (provider.model != null) ["-c" "model=\"${provider.model}\""])} "$@"
              ''
            )
        )
        codex.providers;
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
