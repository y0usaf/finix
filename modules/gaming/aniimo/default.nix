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
    patches =
      (old.patches or [])
      ++ [
        (generators.sourceFile "luajit-opcodes.patch" (generators.patch.render (({
            add,
            del,
            file,
            hunk,
            ...
          }: [
            (file "src/lj_bc.h" [
              (hunk 69 [
                "** M = multiple args/results"
                "*/"
                "#define BCDEF(_) \\"
                (del "  /* Comparison ops. ORDER OPR. */ \\")
                "  _(ISLT,\tvar,\t___,\tvar,\tlt) \\"
                "  _(ISGE,\tvar,\t___,\tvar,\tlt) \\"
                "  _(ISLE,\tvar,\t___,\tvar,\tle) \\"
                "  _(ISGT,\tvar,\t___,\tvar,\tle) \\"
                (del "  \\")
                (del "  _(ISEQV,\tvar,\t___,\tvar,\teq) \\")
                (del "  _(ISNEV,\tvar,\t___,\tvar,\teq) \\")
                "  _(ISEQS,\tvar,\t___,\tstr,\teq) \\"
                "  _(ISNES,\tvar,\t___,\tstr,\teq) \\"
                "  _(ISEQN,\tvar,\t___,\tnum,\teq) \\"
                "  _(ISNEN,\tvar,\t___,\tnum,\teq) \\"
                (add "  _(ISEQV,\tvar,\t___,\tvar,\teq) \\")
                (add "  _(ISNEV,\tvar,\t___,\tvar,\teq) \\")
                "  _(ISEQP,\tvar,\t___,\tpri,\teq) \\"
                "  _(ISNEP,\tvar,\t___,\tpri,\teq) \\"
                (del "  \\")
                (del "  /* Unary test and copy ops. */ \\")
                "  _(ISTC,\tdst,\t___,\tvar,\t___) \\"
                "  _(ISFC,\tdst,\t___,\tvar,\t___) \\"
                "  _(IST,\t___,\t___,\tvar,\t___) \\"
                "  _(ISF,\t___,\t___,\tvar,\t___) \\"
                "  _(ISTYPE,\tvar,\t___,\tlit,\t___) \\"
                "  _(ISNUM,\tvar,\t___,\tlit,\t___) \\"
                (del "  \\")
                (del "  /* Unary ops. */ \\")
                "  _(MOV,\tdst,\t___,\tvar,\t___) \\"
                "  _(NOT,\tdst,\t___,\tvar,\t___) \\"
                "  _(UNM,\tdst,\t___,\tvar,\tunm) \\"
                "  _(LEN,\tdst,\t___,\tvar,\tlen) \\"
                (del "  \\")
                (del "  /* Binary ops. ORDER OPR. VV last, POW must be next. */ \\")
                "  _(ADDVN,\tdst,\tvar,\tnum,\tadd) \\"
                "  _(SUBVN,\tdst,\tvar,\tnum,\tsub) \\"
                "  _(MULVN,\tdst,\tvar,\tnum,\tmul) \\"
                "  _(DIVVN,\tdst,\tvar,\tnum,\tdiv) \\"
                "  _(MODVN,\tdst,\tvar,\tnum,\tmod) \\"
                (del "  \\")
                "  _(ADDNV,\tdst,\tvar,\tnum,\tadd) \\"
                "  _(SUBNV,\tdst,\tvar,\tnum,\tsub) \\"
                "  _(MULNV,\tdst,\tvar,\tnum,\tmul) \\"
                "  _(DIVNV,\tdst,\tvar,\tnum,\tdiv) \\"
                "  _(MODNV,\tdst,\tvar,\tnum,\tmod) \\"
                (del "  \\")
                "  _(ADDVV,\tdst,\tvar,\tvar,\tadd) \\"
                "  _(SUBVV,\tdst,\tvar,\tvar,\tsub) \\"
                "  _(MULVV,\tdst,\tvar,\tvar,\tmul) \\"
                "  _(DIVVV,\tdst,\tvar,\tvar,\tdiv) \\"
                "  _(MODVV,\tdst,\tvar,\tvar,\tmod) \\"
                (del "  \\")
                "  _(POW,\tdst,\tvar,\tvar,\tpow) \\"
                "  _(CAT,\tdst,\trbase,\trbase,\tconcat) \\"
                (del "  \\")
                (del "  /* Constant ops. */ \\")
                "  _(KSTR,\tdst,\t___,\tstr,\t___) \\"
                "  _(KCDATA,\tdst,\t___,\tcdata,\t___) \\"
                "  _(KSHORT,\tdst,\t___,\tlits,\t___) \\"
                "  _(KNUM,\tdst,\t___,\tnum,\t___) \\"
                "  _(KPRI,\tdst,\t___,\tpri,\t___) \\"
                "  _(KNIL,\tbase,\t___,\tbase,\t___) \\"
                (del "  \\")
                (del "  /* Upvalue and function ops. */ \\")
                (del "  _(UGET,\tdst,\t___,\tuv,\t___) \\")
                (del "  _(USETV,\tuv,\t___,\tvar,\t___) \\")
                "  _(USETS,\tuv,\t___,\tstr,\t___) \\"
                "  _(USETN,\tuv,\t___,\tnum,\t___) \\"
                "  _(USETP,\tuv,\t___,\tpri,\t___) \\"
                (del "  _(UCLO,\trbase,\t___,\tjump,\t___) \\")
                (add "  _(UGET,\tdst,\t___,\tuv,\t___) \\")
                (add "  _(USETV,\tuv,\t___,\tvar,\t___) \\")
                "  _(FNEW,\tdst,\t___,\tfunc,\tgc) \\"
                (del "  \\")
                (del "  /* Table ops. */ \\")
                (del "  _(TNEW,\tdst,\t___,\tlit,\tgc) \\")
                (add "  _(UCLO,\trbase,\t___,\tjump,\t___) \\")
                "  _(TDUP,\tdst,\t___,\ttab,\tgc) \\"
                (del "  _(GGET,\tdst,\t___,\tstr,\tindex) \\")
                (del "  _(GSET,\tvar,\t___,\tstr,\tnewindex) \\")
                (del "  _(TGETV,\tdst,\tvar,\tvar,\tindex) \\")
                (add "  _(TNEW,\tdst,\t___,\tlit,\tgc) \\")
                "  _(TGETS,\tdst,\tvar,\tstr,\tindex) \\"
                "  _(TGETB,\tdst,\tvar,\tlit,\tindex) \\"
                "  _(TGETR,\tdst,\tvar,\tvar,\tindex) \\"
                (add "  _(GGET,\tdst,\t___,\tstr,\tindex) \\")
                (add "  _(GSET,\tvar,\t___,\tstr,\tnewindex) \\")
                (add "  _(TGETV,\tdst,\tvar,\tvar,\tindex) \\")
                (add "  _(TSETM,\tbase,\t___,\tnum,\tnewindex) \\")
                (add "  _(TSETR,\tvar,\tvar,\tvar,\tnewindex) \\")
                "  _(TSETV,\tvar,\tvar,\tvar,\tnewindex) \\"
                "  _(TSETS,\tvar,\tvar,\tstr,\tnewindex) \\"
                "  _(TSETB,\tvar,\tvar,\tlit,\tnewindex) \\"
                (del "  _(TSETM,\tbase,\t___,\tnum,\tnewindex) \\")
                (del "  _(TSETR,\tvar,\tvar,\tvar,\tnewindex) \\")
                (del "  \\")
                (del "  /* Calls and vararg handling. T = tail call. */ \\")
                "  _(CALLM,\tbase,\tlit,\tlit,\tcall) \\"
                "  _(CALL,\tbase,\tlit,\tlit,\tcall) \\"
                "  _(CALLMT,\tbase,\t___,\tlit,\tcall) \\"
              ])
              (hunk 161 [
                "  _(ITERN,\tbase,\tlit,\tlit,\tcall) \\"
                "  _(VARG,\tbase,\tlit,\tlit,\t___) \\"
                "  _(ISNEXT,\tbase,\t___,\tjump,\t___) \\"
                (del "  \\")
                (del "  /* Returns. */ \\")
                "  _(RETM,\tbase,\t___,\tlit,\t___) \\"
                "  _(RET,\trbase,\t___,\tlit,\t___) \\"
                "  _(RET0,\trbase,\t___,\tlit,\t___) \\"
                "  _(RET1,\trbase,\t___,\tlit,\t___) \\"
                (del "  \\")
                (del "  /* Loops and branches. I/J = interp/JIT, I/C/L = init/call/loop. */ \\")
                "  _(FORI,\tbase,\t___,\tjump,\t___) \\"
                "  _(JFORI,\tbase,\t___,\tjump,\t___) \\"
                (del "  \\")
                "  _(FORL,\tbase,\t___,\tjump,\t___) \\"
                "  _(IFORL,\tbase,\t___,\tjump,\t___) \\"
                "  _(JFORL,\tbase,\t___,\tlit,\t___) \\"
                (del "  \\")
                "  _(ITERL,\tbase,\t___,\tjump,\t___) \\"
                "  _(IITERL,\tbase,\t___,\tjump,\t___) \\"
                "  _(JITERL,\tbase,\t___,\tlit,\t___) \\"
                (del "  \\")
                "  _(LOOP,\trbase,\t___,\tjump,\t___) \\"
                "  _(ILOOP,\trbase,\t___,\tjump,\t___) \\"
                "  _(JLOOP,\trbase,\t___,\tlit,\t___) \\"
                (del "  \\")
                "  _(JMP,\trbase,\t___,\tjump,\t___) \\"
                (del "  \\")
                (del "  /* Function headers. I/J = interp/JIT, F/V/C = fixarg/vararg/C func. */ \\")
                "  _(FUNCF,\trbase,\t___,\t___,\t___) \\"
                "  _(IFUNCF,\trbase,\t___,\t___,\t___) \\"
                "  _(JFUNCF,\trbase,\t___,\tlit,\t___) \\"
              ])
            ])
          ])
          generators.patch)))
      ];
    env = old.env // {NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE} -DLUAJIT_SECURITY_PRNG=0";};
  });
  patches = map (p: p // {name = p.mod;}) (lib.importJSON ./patches.json);
  rewards = lib.importJSON ./rewards.json // {wrapper = ./rewards.lua;};
  catch = lib.importJSON ./catch.json // {wrapper = ./catch.lua;};
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
      ${pkgs.python3}/bin/python3 ${./apply.py} ${settings} || true
  '';
}
