{lib, ...}: {
  options.user.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start Zellij session on shell startup";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional settings for Zellij configuration";
    };

    zjstatus = {
      enable = lib.mkEnableOption "zjstatus plugin for zellij";

      layout = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Layout configuration for zjstatus";
      };
    };
  };
}
