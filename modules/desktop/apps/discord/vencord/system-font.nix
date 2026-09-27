{
  config,
  lib,
  ...
}: let
  wrapFonts = names: lib.concatStringsSep ", " (map (f: "\"${f}\"") names);
  inherit (config) user;
  inherit (user.ui) fonts;
  uiFontList = [fonts.mainFontName fonts.backup.name];
  primaryFont = wrapFonts (uiFontList ++ [fonts.emoji.name]);
in {
  manzil.users."${user.name}".files.".config/Vencord/themes/system-font.css".text = ''
    :root {
      /* Use system fonts for UI */
      --font-primary: ${primaryFont} !important;
      --font-display: ${primaryFont} !important;
      --font-headline: ${primaryFont} !important;
      --font-code: ${wrapFonts uiFontList} !important;
    }
  '';
}
