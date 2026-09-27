{lib, ...}: {
  options.user.defaults = {
    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "pcmanfm";
      description = "Default file manager";
    };
    launcher = lib.mkOption {
      type = lib.types.str;
      default = "monstar --app-id=launcher -e ~/.config/scripts/tui-launcher.sh";
      description = "Default application launcher";
    };
    discord = lib.mkOption {
      type = lib.types.str;
      default = "discord";
      description = "Default Discord client";
    };
  };
}
