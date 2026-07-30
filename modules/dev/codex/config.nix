{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    manzil.users."${config.user.name}".files.".local/share/codex/config.toml" = {
      type = "merge";
      format = "toml";
      clobber = true;
      value = {
        approval_policy = "never";
        sandbox_mode = "danger-full-access";
      };
    };
  };
}
