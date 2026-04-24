{
  config,
  lib,
  ...
}: let
  fetchGit = {
    rev,
    submodules ? false,
    url,
  }: let
    fetched = builtins.fetchGit {
      inherit url rev submodules;
    };
  in
    if builtins.isAttrs fetched
    then fetched.outPath
    else fetched;

  fetchGitHubTarball = owner: repo: rev: sha256:
    builtins.fetchTarball {
      url = "https://api.github.com/repos/${owner}/${repo}/tarball/${rev}";
      inherit sha256;
    };

  modsData = {
    Aura = builtins.fetchTarball {
      url = "https://github.com/SpectralPack/Aura/archive/dbb6496d163d15e86b0afb6879d32b891164af05.tar.gz";
      sha256 = "1414yivy6rgwgl9mpkps6pnm5mzl2wj7j2fczia6n7020m2dnqg1";
    };

    "Balatro-Stickers-Always-Shown" = fetchGitHubTarball "SirMaiquis" "Balatro-Stickers-Always-Shown" "v1.4.0" "0gsdbn02yg87msvxalz5znpznws6x5n81gyfl5ir29ivn41sr85d";

    HandyBalatro = fetchGitHubTarball "SleepyG11" "HandyBalatro" "v1.5.1" "1bv663n6qns9mi7cgvimkynymig2b06qykryzmskcjlbvl587h37";

    cardsleeves = fetchGit {
      url = "https://github.com/larswijn/CardSleeves.git";
      rev = "c2a22f091fe92d1bcbd547297a837791b6eae771";
    };

    cryptid = fetchGit {
      url = "https://github.com/SpectralPack/Cryptid.git";
      rev = "bca501cbeea487b8ca80198c46e3a4a198856de0";
    };

    jokerdisplay = fetchGit {
      url = "https://github.com/nh6574/JokerDisplay.git";
      rev = "7d7a61761b13894820270f9664d33685f54ec82a";
    };

    multiplayer = fetchGit {
      url = "https://github.com/Balatro-Multiplayer/BalatroMultiplayer.git";
      rev = "c7b1c210f0d6699819222b1767ee9469878d1c52";
    };

    pokermon = fetchGit {
      url = "https://github.com/InertSteak/Pokermon.git";
      rev = "98a06f49be978052bc74a6cba80b08d38f607fd2";
    };

    steamodded = fetchGit {
      url = "https://github.com/Steamodded/smods.git";
      rev = "9bb34e88cbc7d3122944baa038a7b2e5bb3efd10";
    };

    talisman = fetchGit {
      url = "https://github.com/SpectralPack/Talisman.git";
      rev = "372d66c64bf987987cffbe31f731b3d1732526f3";
    };
  };
in {
  options = {
    user.gaming.mods.balatro = lib.mkOption {
      type = with lib.types; attrsOf raw;
      default = modsData;
      internal = true;
    };
  };
}
