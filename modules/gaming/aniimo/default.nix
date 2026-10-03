{
  config,
  lib,
  pkgs,
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
  patches = map (p: p // {name = p.mod;}) (lib.importJSON ./patches.json);
  rewards = lib.importJSON ./rewards.json // {wrapper = ./rewards.lua;};
  mods = lib.optionals cfg.enable (builtins.filter (m: builtins.elem m.name cfg.mods) (patches ++ [rewards]));
  settings = pkgs.writeText "aniimo-mods.json" (builtins.toJSON ({
      gameDirectory = "${config.user.homeDirectory}/${config.user.paths.steam}/steamapps/common/Aniimo";
      inherit mods;
    }
    // lib.optionalAttrs (builtins.elem "rewards" (map (m: m.name) mods)) {luajit = lib.getExe luajit;}));
in {
  options.user.gaming.aniimo = {
    enable = lib.mkEnableOption "Aniimo Lua mods";
    mods = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["camera" "movement" "rewards"]);
      default = ["camera" "movement"];
    };
  };

  config.system.activation.scripts.aniimoMods.text = ''
    ${pkgs.util-linux}/bin/setpriv --reuid=${config.user.name} --regid=users --init-groups \
      ${pkgs.python3}/bin/python3 ${./apply.py} ${settings} || true
  '';
}
