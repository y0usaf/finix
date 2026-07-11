{
  lib,
  pkgs,
  ...
}: let
  # Build-time fetchers (pkgs.fetch*) instead of builtins.fetch*: they don't
  # block evaluation on network, fetch in parallel, and are substitutable.
  fetchGitHub = owner: repo: rev: hash:
    pkgs.fetchFromGitHub {inherit owner repo rev hash;};
in {
  options = {
    user.gaming.mods.balatro = lib.mkOption {
      type = with lib.types; attrsOf raw;
      default = {
        Aura = fetchGitHub "SpectralPack" "Aura" "dbb6496d163d15e86b0afb6879d32b891164af05" "sha256-4WHbRAUCHGtU/MwJeSQX9NdS7TX6zlsTffxl43f0JJA=";

        "Balatro-Stickers-Always-Shown" = fetchGitHub "SirMaiquis" "Balatro-Stickers-Always-Shown" "v1.4.0" "sha256-raCsA7E7JpFjoc6/gGzpRnP7r/3lU9W3rgc9L4BdTT8=";

        HandyBalatro = fetchGitHub "SleepyG11" "HandyBalatro" "v1.5.1" "sha256-Z8CDCt2LSjZ1/T5Pjw1Y4sXqrZ817sdOrElbbOwwZq8=";

        cardsleeves = fetchGitHub "larswijn" "CardSleeves" "c2a22f091fe92d1bcbd547297a837791b6eae771" "sha256-pf0E320SK3LHJ2rZfgKJBXFY0LjNrPVyQv5M+jecedk=";

        cryptid = fetchGitHub "SpectralPack" "Cryptid" "bca501cbeea487b8ca80198c46e3a4a198856de0" "sha256-RkM1bgUR+quYv+oIbGiEN/DYq70lmhiWIElCnyGATd8=";

        jokerdisplay = fetchGitHub "nh6574" "JokerDisplay" "7d7a61761b13894820270f9664d33685f54ec82a" "sha256-Iia+vkXOtRPmo3X+w7PFvB9P8N1jDYpHYr4cKGkmXnQ=";

        multiplayer = fetchGitHub "Balatro-Multiplayer" "BalatroMultiplayer" "c7b1c210f0d6699819222b1767ee9469878d1c52" "sha256-rEHQ7DJd66gE7+5fTmnuBMUngv32W5qYbHgSU9EdIyw=";

        pokermon = fetchGitHub "InertSteak" "Pokermon" "98a06f49be978052bc74a6cba80b08d38f607fd2" "sha256-zkdKh7zBsLDQ9NOcYJnE0mSBA/hbiSeI3w7fFsSyEb8=";

        steamodded = fetchGitHub "Steamodded" "smods" "9bb34e88cbc7d3122944baa038a7b2e5bb3efd10" "sha256-Z+BngswINBGz9XWZ7uhJNr0RmnK63J4LLyXDIEA2LNQ=";

        talisman = fetchGitHub "SpectralPack" "Talisman" "372d66c64bf987987cffbe31f731b3d1732526f3" "sha256-xvEeSHS8wkj7UxvEJ8KYWB7CE9ToHPgXO652XBuJ1j0=";
      };
      internal = true;
    };
  };
}
