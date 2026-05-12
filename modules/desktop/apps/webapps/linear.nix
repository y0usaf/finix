{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.linear = {
    enable = lib.mkEnableOption "Linear webapp";
  };
  config = lib.mkIf config.user.programs.linear.enable {
    manzil.users."${config.user.name}" = {
      files = {
        ".local/share/applications/linear.desktop" = {
          generator = lib.generators.toINI {};
          value."Desktop Entry" = {
            Name = "Linear";
            Exec = "${lib.getExe pkgs.chromium} --app=https://linear.app --enable-features=WebContentsForceDark %U";
            Terminal = false;
            Type = "Application";
            Categories = "Development;ProjectManagement;";
            Comment = "Linear issue tracking and project management";
          };
        };
      };
    };
  };
}
