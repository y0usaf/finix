{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  package = flakeInputs.reasonix-flake.packages."${system}".default;
  apiKeyFile = lib.escapeShellArg "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";

  seedKey = ''
    state_home="''${REASONIX_STATE_HOME:-$HOME/.reasonix}"
    env_file="$state_home/.env"
    if [ -r ${apiKeyFile} ]; then
      key="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < ${apiKeyFile})"
      if [ -n "$key" ] && ! ${pkgs.gnugrep}/bin/grep -qxF "AI_GATEWAY_API_KEY=$key" "$env_file" 2>/dev/null; then
        ${pkgs.coreutils}/bin/mkdir -p "$state_home"
        tmp="$(${pkgs.coreutils}/bin/mktemp "$state_home/.env.XXXXXX")"
        {
          echo "AI_GATEWAY_API_KEY=$key"
          ${pkgs.gnugrep}/bin/grep -v '^AI_GATEWAY_API_KEY=' "$env_file" 2>/dev/null || true
        } > "$tmp"
        ${pkgs.coreutils}/bin/chmod 600 "$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$env_file"
      fi
    fi
  '';
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "reasonix" ''
      ${seedKey}
      for a in "$@"; do
        if [ "$a" = "acp" ]; then
          exec ${package}/bin/reasonix "$@"
        fi
        case "$a" in
          -*);;
          *) break;;
        esac
      done
      exec ${package}/bin/reasonix --yolo "$@"
    '')
  ];

  manzil.users."${config.user.name}".files = {
    ".reasonix/REASONIX.md" = {
      type = "copy";
      text = config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments;
    };

    ".reasonix/config.toml" = {
      type = "merge";

      format = "toml";

      clobber = true;

      value = {
        default_model = "glm-5.3-flash";

        telemetry.cli_metrics = "off";

        permissions.mode = "allow";

        sandbox.bash = "off";

        desktop.check_updates = false;

        providers = [
          {
            name = "glm-5.3-flash";

            kind = "openai";

            base_url = "https://ai-gateway.vercel.sh/v1";

            model = "glm-5.3-flash";

            api_key_env = "AI_GATEWAY_API_KEY";

            context_window = 1000000;
          }
        ];
      };
    };
  };
}
