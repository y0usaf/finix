{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  inherit (lib.generators) toJSON;
in {
  config = lib.mkIf cfg.enable {
    manzil.users."${config.user.name}".files = {
      ".pi/agent/models.json" = {
        generator = toJSON {};
        value = {
          providers = {
            vercel-ai-gateway = {
              modelOverrides = {
                # Unlock xhigh+max thinking on DeepSeek V4 Flash via Vercel AI Gateway.
                # Without this, xhigh and max are missing from the thinkingLevelMap and
                # cannot be selected in /thinking or /model patterns.
                "deepseek/deepseek-v4-flash-0731" = {
                  thinkingLevelMap = {
                    xhigh = "xhigh";
                    max = "max";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}