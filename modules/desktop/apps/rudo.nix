{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  userAppearance = config.user.appearance;
in {
  environment.systemPackages = [flakeInputs.rudo.packages."${system}".default];

  manzil.users."${config.user.name}".files = {
    ".config/rudo/config.toml" = {
      source = (pkgs.formats.toml {}).generate "rudo-config" {
        window = {
          opacity = 0.7;
        };
        font = {
          size = userAppearance.termFontSize;
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
