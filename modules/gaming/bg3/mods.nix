{
  bg3se = {
    version = "updater-20240430";
  };

  "game-mods" = builtins.fetchTarball {
    url = "https://github.com/y0usaf/game-mods/archive/d54ec2dfad1e2116bf11c461e30d6fbf78e91df3.tar.gz";
    sha256 = "sha256-Vw7t9JGzi3mcz4lSgGtuq9GHKN8eZZX46LcmkCJGxdk=";
  };
}
