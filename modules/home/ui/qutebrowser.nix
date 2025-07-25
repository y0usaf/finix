{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.qutebrowser;
in {
  options.home.ui.qutebrowser = {
    enable = lib.mkEnableOption "qutebrowser web browser";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        qutebrowser
      ];
      file.xdg_config."qutebrowser/config.py".text = ''
        # Basic qutebrowser configuration
        config.load_autoconfig(False)

        # Basic settings
        c.zoom.default = 110
        c.fonts.default_family = "monospace"
        c.fonts.default_size = "11pt"

        # Tab settings
        c.tabs.position = "top"
        c.tabs.show = "multiple"
        c.tabs.background = True

        # Downloads
        c.downloads.location.directory = "~/Downloads"

        # Privacy settings
        c.content.cookies.accept = "no-3rdparty"
        c.content.geolocation = "ask"
        c.content.notifications.enabled = "ask"

        # Dark mode
        c.colors.webpage.darkmode.enabled = True
        c.colors.webpage.preferred_color_scheme = "dark"

        # Keybindings
        config.bind('J', 'tab-prev')
        config.bind('K', 'tab-next')
        config.bind('x', 'tab-close')
        config.bind('X', 'undo')
        config.bind('t', 'open -t')
        config.bind('T', 'open -t -r')

        # Search engines
        c.url.searchengines = {
            'DEFAULT': 'https://duckduckgo.com/?q={}',
            'g': 'https://www.google.com/search?q={}',
            'gh': 'https://github.com/search?q={}',
            'nix': 'https://search.nixos.org/packages?query={}',
        }

        # Homepage
        c.url.start_pages = ["https://duckduckgo.com"]
        c.url.default_page = "https://duckduckgo.com"
      '';
    };
  };
}
