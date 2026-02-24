{
  config,
  lib,
  ...
}: let
  stableEnabled = config.user.programs.discord.stable.enable or false;
  canaryEnabled = config.user.programs.discord.canary.enable or false;
  discordEnabled = stableEnabled || canaryEnabled;

  font = config.user.ui.fonts;
  wrapFonts = fonts: lib.concatStringsSep ", " (map (f: "\"${f}\"") fonts);
  primaryFont = wrapFonts [font.mainFontName font.backup.name font.emoji.name];
  monoFont = wrapFonts [font.mainFontName font.backup.name];
in {
  config = lib.mkIf discordEnabled {
    hjem.users.${config.user.name}.files.".config/Vencord/themes/system-font.css".text = ''
      :root {
        /* Use system fonts for UI */
        --font-primary: ${primaryFont} !important;
        --font-display: ${primaryFont} !important;
        --font-headline: ${primaryFont} !important;
        --font-code: ${monoFont} !important;
      }
    '';
  };
}
