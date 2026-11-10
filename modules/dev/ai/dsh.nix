{
  pkgs,
  inputPackages,
  ...
}: let
  inherit (inputPackages.deepseek-harness-flake) dsh;
  model = "deepseek/deepseek-v4.1-flash-1017-fast";
  patch = pkgs.writeText "dsh-vercel.yml" (builtins.toJSON [
    {
      id = "llm-pi-ai";
      config.providers.vercel-gateway = {
        api = "anthropic-messages";
        baseURL = "https://ai-gateway.vercel.sh";
        apiKeyEnv = "VERCEL_AI_GATEWAY_API_KEY";
        models = [
          {
            id = model;
            name = "DeepSeek V4.1 Flash 1017 Fast";
            input = ["text" "image"];
            contextWindow = 1000000;
            maxTokens = 384000;
          }
        ];
      };
    }
    {
      id = "agent-default-model";
      config = {
        provider = "vercel-gateway";
        inherit model;
      };
    }
    {
      id = "acp";
      config = {
        provider = "vercel-gateway";
        inherit model;
      };
    }
  ]);
  dshAcp = pkgs.writeShellApplication {
    name = "dsh-acp";
    runtimeInputs = [dsh pkgs.jq];
    text = ''
      VERCEL_AI_GATEWAY_API_KEY=$(crest-auth json token vercel-ai-gateway ${model} | jq -r '.key // .access')
      export DSH_HOME="''${DSH_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}/dsh}"
      export VERCEL_AI_GATEWAY_API_KEY
      exec dsh acp --patch ${patch} "$@"
    '';
  };
in {
  environment.systemPackages = [dsh dshAcp];

  user.persist.directories = [".local/state/dsh"];
}
