{
  config,
  lib,
  ...
}: let
  wrapFonts = fonts: lib.concatStringsSep ", " (map (f: "\"${f}\"") fonts);
  primaryFont = wrapFonts [config.user.ui.fonts.mainFontName config.user.ui.fonts.backup.name config.user.ui.fonts.emoji.name];
  monoFont = wrapFonts [config.user.ui.fonts.mainFontName config.user.ui.fonts.backup.name];
in {
  config =
    lib.mkIf (
      (config.user.programs.discord.stable.enable or false)
      || (config.user.programs.discord.canary.enable or false)
    ) {
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
