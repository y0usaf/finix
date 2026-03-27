{
  config,
  lib,
  ...
}: let
  wrapFonts = fonts: lib.concatStringsSep ", " (map (f: "\"${f}\"") fonts);
  inherit (config) user;
  inherit (user.ui) fonts;
  inherit (user.programs) discord;
  uiFontList = [fonts.mainFontName fonts.backup.name];
  primaryFont = wrapFonts (uiFontList ++ [fonts.emoji.name]);
in {
  config =
    lib.mkIf (
      (discord.stable.enable or false)
      || (discord.canary.enable or false)
    ) {
      bayt.users."${user.name}".files.".config/Vencord/themes/system-font.css".text = ''
        :root {
          /* Use system fonts for UI */
          --font-primary: ${primaryFont} !important;
          --font-display: ${primaryFont} !important;
          --font-headline: ${primaryFont} !important;
          --font-code: ${wrapFonts uiFontList} !important;
        }
      '';
    };
}
