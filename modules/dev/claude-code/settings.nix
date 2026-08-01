{
  config,
  lib,
  ...
}: let
  inherit (config) user;
in {
  config = lib.mkIf config.user.dev.claude-code.enable {
    manzil.users."${user.name}".files.".local/share/claude/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        permissions.defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
      };
    };
  };
}
