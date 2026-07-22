{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.kimi-code;
  homeDir = config.user.homeDirectory;
  kimiPkg = pkgs.callPackage ../../packages/kimi-code.nix {};
in {
  options.user.dev.kimi-code = {
    enable = lib.mkEnableOption "Kimi Code CLI with Vercel AI Gateway provider";

    package = lib.mkOption {
      type = lib.types.package;
      default = kimiPkg;
      description = "Kimi Code package.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "moonshotai/kimi-k3";
      description = "Model id sent to Vercel AI Gateway (becomes the default model).";
    };

    maxContextSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1000000;
      description = "max_context_size for the default model.";
    };
    displayName = lib.mkOption {
      type = lib.types.str;
      default = "Kimi K3 (Vercel)";
      description = "display_name for the default model.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.str;
      example = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
      description = ''
        Path (string, not path literal) to a file containing the Vercel AI
        Gateway key. Read by the `kimi` wrapper at launch and injected into
        $KIMI_CODE_HOME/config.toml — never copied into the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.apiKeyFile != "";
        message = "user.dev.kimi-code.apiKeyFile must point at a Vercel AI Gateway key file.";
      }
    ];

    # Provider + model declarations, merged into the mutable config.toml at
    # activation/boot by patchix (login rewrites survive; patches re-merge).
    # api_key stays an empty placeholder — the kimi wrapper below fills it in.
    patchix = {
      enable = true;
      # KIMI_CODE_HOME is pinned to ~/.local/share/kimi-code in xdg.nix.
      users."${config.user.name}".patches.".local/share/kimi-code/config.toml" = {
        format = "toml";
        value = {
          default_model = "vercel/${cfg.model}";
          providers.vercel = {
            type = "openai";
            base_url = "https://ai-gateway.vercel.sh/v1";
            api_key = "";
          };
          models."vercel/${cfg.model}" = {
            provider = "vercel";
            model = cfg.model;
            max_context_size = cfg.maxContextSize;
            capabilities = ["thinking" "image_in" "tool_use"];
            display_name = cfg.displayName;
          };
        };
      };
    };

    # `kimi` wrapper: inject the gateway key from apiKeyFile into the
    # providers.vercel placeholder (idempotent), then exec the real binary.
    # Needed because kimi-code reads credentials only from config.toml, never
    # from shell env.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "kimi" ''
        config_file="''${KIMI_CODE_HOME:-${homeDir}/.local/share/kimi-code}/config.toml"
        if [ -f "$config_file" ] && ${pkgs.gnugrep}/bin/grep -q 'api_key = ""' "$config_file"; then
          key="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < ${lib.escapeShellArg cfg.apiKeyFile})"
          ${pkgs.gnused}/bin/sed -i "/\[providers.vercel\]/,/^\[/s/^api_key = \"\"\$/api_key = \"$key\"/" "$config_file"
        fi
        exec ${cfg.package}/bin/kimi "$@"
      '')
    ];
  };
}
