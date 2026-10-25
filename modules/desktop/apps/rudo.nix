{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [flakeInputs.rudo.packages.${pkgs.stdenv.hostPlatform.system}.default];

  manzil.users."${config.user.name}".files = {
    ".config/rudo/config.toml" = {
      source = (pkgs.formats.toml {}).generate "rudo-config" {
        window = {
          inherit (config.user.appearance.glass) opacity;
        };
        font = {
          size = config.user.appearance.termFontSize;
          family = config.user.ui.fonts.mainFontName;
        };
        keybindings = {
          copy = "ctrl+c";
          paste = "ctrl+v";
        };
      };
    };
  };
}
