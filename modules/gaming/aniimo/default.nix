{
  config,
  lib,
  pkgs,
  generators,
  ...
}: let
  cfg = config.user.gaming.aniimo;
  luajit = (pkgs.luajit.override {enable52Compat = true;}).overrideAttrs (old: {
    pname = "luajit-aniimo";
    version = "2.1.0-beta3-unstable-2022-06-23";
    src = pkgs.fetchFromGitHub {
      owner = "LuaJIT";
      repo = "LuaJIT";
      rev = "4c2441c16ce3c4e312aaefecc6d40c4fe21de97c";
      hash = "sha256-S1oVxgqitKPENLIbBfrmY8w8GgBQR6Byr52RjPpqz8g=";
    };
    patches = (old.patches or []) ++ [./luajit-opcodes.patch];
    env = old.env // {NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE} -DLUAJIT_SECURITY_PRNG=0";};
  });
  patches = map (p: p // {name = p.mod;}) (import ./patches.data.nix);
  rewards = import ./rewards.data.nix // {wrapper = generators.sourceFile "rewards.lua" (generators.luaSource (import ./rewards-lua.data.nix));};
  catch = import ./catch.data.nix // {wrapper = generators.sourceFile "catch.lua" (generators.luaSource (import ./catch-lua.data.nix));};
  mods = lib.optionals cfg.enable (builtins.filter (m: builtins.elem m.name cfg.mods) (patches ++ [rewards catch]));
  settings = pkgs.writeText "aniimo-mods.json" (builtins.toJSON ({
      gameDirectory = "${config.user.homeDirectory}/${config.user.paths.steam}/steamapps/common/Aniimo";
      inherit mods;
    }
    // lib.optionalAttrs (builtins.any (m: m ? wrapper) mods) {luajit = lib.getExe luajit;}));
in {
  options.user.gaming.aniimo = {
    enable = lib.mkEnableOption "Aniimo Lua mods";
    mods = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["camera" "movement" "rewards" "catch"]);
      default = ["camera" "movement"];
    };
  };

  config.system.activation.scripts.aniimoMods.text = ''
    ${pkgs.util-linux}/bin/setpriv --reuid=${config.user.name} --regid=users --init-groups \
      ${pkgs.python3}/bin/python3 ${generators.sourceFile "apply.py" (generators.pythonSource (import ./apply.data.nix))} ${settings} || true
  '';
}
