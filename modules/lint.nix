{
  inputs,
  inputPackages,
  lib,
  pkgs,
  hosts,
  droid,
}: let
  strictix = lib.getExe' inputPackages.strictix.default "strictix";

  schema = name: docs:
    pkgs.writeText "${name}-options.json" (builtins.toJSON {
      options = builtins.listToAttrs (map (o: {
          inherit (o) name;
          value.type = o.type or "";
        })
        docs);
    });

  codecs = {
    json = {
      extensions = ["json"];
      parse = builtins.fromJSON;
      render = lib.generators.toJSON {};
    };
    toml = {
      extensions = ["toml"];
      parse = builtins.fromTOML;
      render = v: builtins.readFile ((pkgs.formats.toml {}).generate "x.toml" v);
    };
  };

  importers = lib.attrNames (lib.filterAttrs (_: c: !(c ? parse)) codecs);

  convert = literal;

  literal = c: let
    codec = codecs.${c.id};
    value = codec.parse c.text;
    nix = lib.generators.toPretty {multiline = true;} value;
    generate = name: v: "(pkgs.formats.${c.id} {}).generate ${lib.strings.escapeNixString (baseNameOf name)} (${v})";
    forms = {
      json = "(builtins.toJSON (${nix}))";
      toml = "(builtins.readFile (${generate c.entry nix}))";
      import = "import ${c.data}";
      source = "(${generate c.target "import ${c.data}"})";
    };
    form =
      if c.kind == "text"
      then c.id
      else c.loader;
    failures = imported: [
      {
        failed = !(c.pkgs || builtins.elem form ["json" "import"]);
        reason = "pkgs is not in scope";
      }
      {
        failed = imported != value;
        reason = "toPretty does not reproduce the value";
      }
      {
        failed = codec.parse (codec.render imported) != value;
        reason = "rendering the Nix value does not parse back to the original";
      }
    ];
  in {
    inherit nix;
    replacement = forms.${form};
    reason = imported: (lib.findFirst (f: f.failed) {reason = null;} (failures imported)).reason;
  };

  sources = {
    lisp = {
      "tomoe-bar.lisp" = ./desktop/session/tomoe/lisp/bar.lisp;
      "tomoe-cassette.lisp" = ./desktop/session/tomoe/lisp/cassette.lisp;
      "tomoe-deck.lisp" = ./desktop/session/tomoe/lisp/deck.lisp;
      "tomoe-gap.lisp" = ./desktop/session/tomoe/lisp/gap.lisp;
      "tomoe-glass.lisp" = ./desktop/session/tomoe/lisp/glass.lisp;
      "tomoe-hud.lisp" = ./desktop/session/tomoe/lisp/hud.lisp;
      "tomoe-peek.lisp" = ./desktop/session/tomoe/lisp/peek.lisp;
      "tomoe-plates.lisp" = ./desktop/session/tomoe/lisp/plates.lisp;
      "tomoe-policy.lisp" = ./desktop/session/tomoe/lisp/policy.lisp;
      "tomoe-shader-wallpaper.lisp" = ./desktop/session/tomoe/lisp/shader-wallpaper.lisp;
      "tomoe-spine.lisp" = ./desktop/session/tomoe/lisp/spine.lisp;
      "tomoe-sway.lisp" = ./desktop/session/tomoe/lisp/sway.lisp;
      "tomoe-theme.lisp" = ./desktop/session/tomoe/lisp/theme.lisp;
      "tomoe-user.lisp" = ./desktop/session/tomoe/lisp/user.lisp;
      "ekko-init.lisp" = ./shell/ekko/init.lisp;
    };
    javascript."jev-mcp.mjs" = ./dev/ai/jev-mcp.mjs;
    lua = {
      "aniimo-catch.lua" = ./gaming/aniimo/catch.lua;
      "aniimo-rewards.lua" = ./gaming/aniimo/rewards.lua;
      "omarchy-hyprland.lua" = ./hosts/steam-frame/omarchy/hyprland.lua;
    };
    shell = {
      "beat-saber-lock" = ./hosts/steam-frame/beat-saber/lock.sh;
      "omp-box" = ../omp-box/omp-box.sh;
    };
    glsl = {
      "ozette-dark.glsl" = ./desktop/session/tomoe/shaders/ozette-dark.glsl;
      "ozette-fields-dark.glsl" = ./desktop/session/tomoe/shaders/ozette-fields-dark.glsl;
      "ozette-fields-light.glsl" = ./desktop/session/tomoe/shaders/ozette-fields-light.glsl;
      "ozette-light.glsl" = ./desktop/session/tomoe/shaders/ozette-light.glsl;
      "ozette-lilies-dark.glsl" = ./desktop/session/tomoe/shaders/ozette-lilies-dark.glsl;
      "ozette-lilies-light.glsl" = ./desktop/session/tomoe/shaders/ozette-lilies-light.glsl;
      "ozette-pond-dark.glsl" = ./desktop/session/tomoe/shaders/ozette-pond-dark.glsl;
      "ozette-pond-light.glsl" = ./desktop/session/tomoe/shaders/ozette-pond-light.glsl;
    };
    luau = {
      "tern-block-menu-window.luau" = ./tools/tern/config/plugins/block-menu/window.luau;
      "tern-tab-order-window.luau" = ./tools/tern/config/plugins/tab-order/window.luau;
      "tern-tuturu-window.luau" = ./tools/tern/config/plugins/tuturu/src/window.luau;
      "tern-ui-menu-rail.luau" = ./tools/tern/config/plugins/ui-menu/rail.luau;
      "tern-ui-menu-window.luau" = ./tools/tern/config/plugins/ui-menu/window.luau;
    };
    markdown = {
      "carly-HEARTBEAT.md" = ./tools/tern/config/carly/HEARTBEAT.md;
      "carly-MEMORY.md" = ./tools/tern/config/carly/MEMORY.md;
      "carly-SOUL.md" = ./tools/tern/config/carly/SOUL.md;
      "carly-USER.md" = ./tools/tern/config/carly/USER.md;
      "carly-2026-10-29.md" = ./tools/tern/config/carly/memory/2026-10-29.md;
      "carly-2026-10-30.md" = ./tools/tern/config/carly/memory/2026-10-30.md;
      "tuturu-README.md" = ./tools/tern/config/plugins/tuturu/README.md;
    };
    python = {
      "apply-reasoning-policy.py" = ./dev/ai/codex/apply-reasoning-policy.py;
      "gateway-proxy.py" = ../omp-box/gateway-proxy.py;
      "wrapper.py" = ./dev/work/vercel/wrapper.py;
      "aniimo-apply.py" = ./gaming/aniimo/apply.py;
      "p4g-setup.py" = ./gaming/p4g/setup.py;
    };
    ts = {
      "omp/box-commands.ts" = ./dev/ai/omp/box-commands.ts;
      "omp/chat-look.ts" = ./dev/ai/omp/chat-look.ts;
      "omp/compact-eval.ts" = ./dev/ai/omp/compact-eval.ts;
      "omp/crest-auth.ts" = ./dev/ai/omp/crest-auth.ts;
      "omp/cwd.ts" = ./dev/ai/omp/cwd.ts;
      "omp/work-fold.ts" = ./dev/ai/omp/work-fold.ts;
      "optchat/extension.ts" = ./dev/ai/omp/optchat/extension.ts;
      "optchat/service.ts" = ./dev/ai/omp/optchat/service.ts;
      "optchat/store.ts" = ./dev/ai/omp/optchat/store.ts;
      "optchat/tree.ts" = ./dev/ai/omp/optchat/tree.ts;
      "pi/crest-auth.ts" = ./dev/ai/pi/crest-auth.ts;
    };
    vbs."play.vbs" = ./tools/tern/config/plugins/tuturu/scripts/play.vbs;
    patch = {
      "luajit-opcodes.patch" = ./gaming/aniimo/luajit-opcodes.patch;
      "aquamarine-gamescope.patch" = ./hosts/steam-frame/omarchy/aquamarine-gamescope.patch;
      "rush-login-command.patch" = ./shell/rush-login-command.patch;
      "omp-prewalk-eval.patch" = ./dev/ai/omp/prewalk-eval.patch;
    };
  };

  patched = {
    "luajit-opcodes.patch" = pkgs.fetchFromGitHub {
      owner = "LuaJIT";
      repo = "LuaJIT";
      rev = "4c2441c16ce3c4e312aaefecc6d40c4fe21de97c";
      hash = "sha256-S1oVxgqitKPENLIbBfrmY8w8GgBQR6Byr52RjPpqz8g=";
    };
    "aquamarine-gamescope.patch" = inputs.steam-frame-nixos.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.aquamarine.src;
    "rush-login-command.patch" = inputPackages.rush.default.src;
    "omp-prewalk-eval.patch" = inputPackages.oh-my-pi.omp.src;
  };

  read = lib.mapAttrs (_: lib.mapAttrs (_: builtins.readFile)) (lib.recursiveUpdate sources {
    glsl = {
      "balatro.glsl" = ./desktop/session/tomoe/shaders/balatro.glsl;
      "cassette-led.glsl" = ./desktop/session/tomoe/shaders/cassette-led.glsl;
      "cassette-squares.glsl" = ./desktop/session/tomoe/shaders/cassette-squares.glsl;
      "dot-corridor.glsl" = ./desktop/session/tomoe/shaders/dot-corridor.glsl;
      "glass-mound.glsl" = ./desktop/session/tomoe/shaders/glass-mound.glsl;
      "hex-spiral.glsl" = ./desktop/session/tomoe/shaders/hex-spiral.glsl;
      "llama-herd.glsl" = ./desktop/session/tomoe/shaders/llama-herd.glsl;
      "llama-herd-night.glsl" = ./desktop/session/tomoe/shaders/llama-herd-night.glsl;
      "su-ei.glsl" = ./desktop/session/tomoe/shaders/su-ei.glsl;
    };
    luau."tern-agent-tabs-window.luau" = ./tools/tern/config/plugins/agent-tabs/window.luau;
    shell."osc.sh" = ./desktop/session/theme/templates/osc.sh;
    ts = lib.mapAttrs' (name: _: lib.nameValuePair "secrets/${name}" (./dev/ai/omp/secrets + "/${name}")) (builtins.readDir ./dev/ai/omp/secrets);
  });

  rendered = lib.recursiveUpdate read {python."wrapper.py" = builtins.replaceStrings ["@owners@"] ["{}"] read.python."wrapper.py";};

  reader = pkgs.writeText "read.lisp" ''
    (let ((*read-eval* nil))
      (with-open-file (source (sb-ext:posix-getenv "SOURCE"))
        (loop for form = (read source nil source) until (eq form source))))
  '';

  prelude = pkgs.writeText "prelude.frag" ''
    #version 300 es
    precision highp float;
    precision highp int;
    uniform vec3 iResolution;
    uniform float iTime;
    uniform int iFrame;
    uniform vec4 iMouse;
    uniform sampler2D iChannel0;
    in vec2 v_local;
    out vec4 tomoe_color;
    #line 1
  '';

  entry = pkgs.writeText "entry.frag" ''

    void main() {
        mainImage(tomoe_color, vec2(v_local.x, iResolution.y - v_local.y));
    }
  '';

  luajit = ["aniimo-catch.lua" "aniimo-rewards.lua"];

  languageChecks = {
    glsl = file: "cat ${prelude} ${file} ${entry} > shader.frag\n${lib.getExe' pkgs.glslang "glslangValidator"} -S frag shader.frag\n";
    javascript = file: "${lib.getExe pkgs.nodejs} --check ${file}\n";
    lisp = file: "SOURCE=${file} ${lib.getExe pkgs.sbcl} --script ${reader}\n";
    lua = file:
      if builtins.elem file.name luajit
      then "${lib.getExe pkgs.luajit} -bl ${file} > /dev/null\n"
      else "${lib.getExe' pkgs.lua5_5 "luac"} -p ${file}\n";
    luau = file: "${lib.getExe' pkgs.luau "luau-analyze"} --formatter=plain ${file} > analysis || true\nif grep -F SyntaxError analysis; then exit 1; fi\n";
    markdown = file: "${comrak} -e table -t xml ${file} > ast\n${comrak} -e table -t commonmark ${file} | ${comrak} -e table -t xml | cmp ast -\n";
    patch = file: "${lib.getExe pkgs.git} -C ${patched.${file.name}} apply --check ${file}\n";
    python = file: "PYTHONPYCACHEPREFIX=$TMPDIR/pycache ${lib.getExe pkgs.python3} -m py_compile ${file}\n";
    shell = file: "${lib.getExe pkgs.bash} -n ${file}\n${lib.getExe pkgs.shellcheck} -s bash -S warning ${file}\n";
    vbs = file: "${strictix} import vbs ${file} > /dev/null\n";
  };

  comrak = lib.getExe pkgs.comrak;

  glslGate = pkgs.writeShellApplication {
    name = "glsl-gate";
    runtimeInputs = [pkgs.clang-tools pkgs.glslang];
    runtimeEnv = {
      GLSL_GRAMMAR = "${pkgs.tree-sitter-grammars.tree-sitter-glsl}/parser";
      GLSL_PRELUDE = prelude;
      GLSL_ENTRY = entry;
      GLSL_STYLE = pkgs.writeText "clang-format" ''
        BasedOnStyle: LLVM
        IndentWidth: 4
        ColumnLimit: 100
        MaxEmptyLinesToKeep: 0
      '';
      __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
      LD_LIBRARY_PATH = "${pkgs.libglvnd}/lib";
    };
    text = ''
      exec ${pkgs.python3.withPackages (ps: [ps.moderngl ps.tree-sitter])}/bin/python ${pkgs.writeText "glsl-gate.py" ''
        import ctypes
        import difflib
        import os
        import re
        import struct
        import subprocess
        import sys
        import tempfile

        import moderngl
        from tree_sitter import Language, Parser

        grammar = ctypes.cdll.LoadLibrary(os.environ["GLSL_GRAMMAR"])
        grammar.tree_sitter_glsl.restype = ctypes.c_void_p
        parser = Parser(Language(grammar.tree_sitter_glsl()))
        masked = re.compile(r"(?<![A-Za-z0-9_])(bool|double|float|int|uint)\(")
        frames = [(640, 360, t) for t in (0.0, 1.7, 13.3, 61.25)]


        def parse(source):
            text = masked.sub(lambda m: "_" + m.group(1)[1:] + "(", source)
            return parser.parse(text.encode()), source.encode()


        def number(text):
            sign = ""
            if text.startswith("-"):
                sign, text = "-", text[1:]
            unsigned = text[-1] in "uU"
            digits = text[:-1] if unsigned else text
            if digits[:2].lower() == "0x":
                value = str(int(digits, 16))
            elif any(c in digits for c in ".eE"):
                value = repr(float(digits))
            else:
                value = str(int(digits, 10))
            return sign + value + ("u" if unsigned else "")


        def canon(node, source):
            kind = node.type
            named = node.named_children
            if kind == "parenthesized_expression" and len(named) == 1:
                return canon(named[0], source)
            if kind == "number_literal":
                return number(source[node.start_byte:node.end_byte].decode())
            if kind == "binary_expression":
                left = canon(node.child_by_field_name("left"), source)
                right = canon(node.child_by_field_name("right"), source)
                return "(" + left + " " + node.child_by_field_name("operator").type + " " + right + ")"
            if kind == "unary_expression":
                operator = node.child_by_field_name("operator").type
                argument = node.child_by_field_name("argument")
                while argument.type == "parenthesized_expression" and len(argument.named_children) == 1:
                    argument = argument.named_children[0]
                if operator == "-" and argument.type == "number_literal":
                    return number("-" + source[argument.start_byte:argument.end_byte].decode())
                return "(" + operator + canon(argument, source) + ")"
            if kind == "conditional_expression":
                parts = [canon(node.child_by_field_name(f), source) for f in ("condition", "consequence", "alternative")]
                return "(" + parts[0] + " ? " + parts[1] + " : " + parts[2] + ")"
            if kind in ("if_statement", "for_statement", "while_statement", "else_clause"):
                out = []
                for child in node.children:
                    if child.is_named and child.type not in ("compound_statement", "parenthesized_expression", "condition_clause", "if_statement", "else_clause", "declaration") and child.type.endswith("statement"):
                        out.append("{ " + canon(child, source) + " }")
                    else:
                        out.append(canon(child, source))
                return " ".join(out)
            if kind == "declaration" and len(node.children_by_field_name("declarator")) > 1:
                head = []
                for child in node.children:
                    if child.id == node.child_by_field_name("declarator").id:
                        break
                    head.append(canon(child, source))
                return " ".join(" ".join(head) + " " + canon(d, source) + ";" for d in node.children_by_field_name("declarator"))
            if kind in ("preproc_def", "preproc_function_def"):
                name = canon(node.child_by_field_name("name"), source)
                params = node.child_by_field_name("parameters")
                if params is not None:
                    name += "(" + ", ".join(canon(p, source) for p in params.named_children) + ")"
                body = source[node.child_by_field_name("value").start_byte:node.child_by_field_name("value").end_byte].decode().strip()
                tree, wrapped = parse("int _ = " + body + ";\n")
                value = tree.root_node.child(0).child_by_field_name("declarator").child_by_field_name("value")
                return "#define " + name + " " + canon(value, wrapped) + "\n"
            if node.child_count == 0:
                return source[node.start_byte:node.end_byte].decode()
            return " ".join(canon(child, source) for child in node.children)


        def normal(source):
            tree, raw = parse(source)
            if tree.root_node.has_error:
                sys.exit("the grammar does not parse the shader")
            items = sorted(canon(child, raw).strip() for child in tree.root_node.children)
            text = "\n".join(items) + "\n"
            return subprocess.run(["clang-format", "--style=file:" + os.environ["GLSL_STYLE"], "--assume-filename=shader.glsl"], input=text, capture_output=True, text=True, check=True).stdout


        def validate(path):
            shader = open(os.environ["GLSL_PRELUDE"]).read() + open(path).read() + open(os.environ["GLSL_ENTRY"]).read()
            with tempfile.TemporaryDirectory() as directory:
                frag = os.path.join(directory, "shader.frag")
                with open(frag, "w") as out:
                    out.write(shader)
                subprocess.run(["glslangValidator", "-S", "frag", frag], check=True, stdout=subprocess.DEVNULL)
            return shader


        def render(context, shader):
            vertex = "#version 330 core\nin vec2 pos;\nout vec2 v_local;\nuniform vec3 iResolution;\nvoid main() { v_local = (pos * 0.5 + 0.5) * iResolution.xy; v_local.y = iResolution.y - v_local.y; gl_Position = vec4(pos, 0.0, 1.0); }\n"
            program = context.program(vertex_shader=vertex, fragment_shader=shader.replace("#version 300 es", "#version 330 core", 1))
            quad = context.buffer(struct.pack("8f", -1, -1, 1, -1, -1, 1, 1, 1))
            array = context.vertex_array(program, [(quad, "2f", "pos")])
            out = []
            for width, height, time in frames:
                target = context.texture((width, height), 4, dtype="f4")
                framebuffer = context.framebuffer(color_attachments=[target])
                framebuffer.use()
                framebuffer.clear()
                program["iResolution"].value = (width, height, 1.0)
                if "iTime" in program:
                    program["iTime"].value = time
                array.render(moderngl.TRIANGLE_STRIP)
                out.append(framebuffer.read(components=4, dtype="f4"))
            return out


        def software():
            for index in range(8):
                try:
                    context = moderngl.create_standalone_context(backend="egl", device_index=index)
                except Exception:
                    continue
                if "llvmpipe" in context.info["GL_RENDERER"]:
                    return context
                context.release()
            sys.exit("no llvmpipe EGL device")


        def main():
            context = software()
            renderer = context.info["GL_RENDERER"]
            failed = False
            pairs = sys.argv[1:]
            if not pairs or len(pairs) % 2:
                sys.exit("usage: glsl-gate ORIGINAL GENERATED [ORIGINAL GENERATED ...]")
            for original, generated in zip(pairs[::2], pairs[1::2]):
                label = os.path.basename(generated)
                before, after = normal(open(original).read()), normal(open(generated).read())
                if before != after:
                    failed = True
                    sys.stdout.writelines(difflib.unified_diff(before.splitlines(True), after.splitlines(True), original, generated))
                    continue
                images = [render(context, validate(path)) for path in (original, generated)]
                same = sum(a == b for a, b in zip(*images))
                print(f"{label}: clang-format equal, glslang ok, {same}/{len(frames)} frames bit-identical ({renderer})")
                failed |= same != len(frames)
            sys.exit(1 if failed else 0)


        main()
      ''} "$@"
    '';
  };

  ambient = pkgs.writeText "ambient.d.ts" ''
    declare module "@oh-my-pi/pi-coding-agent" {
      export type ExtensionAPI = any;
      export type ExtensionContext = any;
    }
    declare module "@earendil-works/pi-coding-agent" {
      export type ExtensionAPI = any;
    }
    declare module "@oh-my-pi/pi-ai" {
      export type ApiKeyResolver = any;
      export const completeSimple: (...args: any[]) => any;
      export const streamSimple: any;
    }
    declare module "@earendil-works/pi-ai" {
      export type Api = any;
      export type AssistantMessage = any;
      export type AssistantMessageEvent = any;
      export type Model<T> = any;
      export type Provider = any;
      export const createAssistantMessageEventStream: any;
    }
    declare module "*";
    declare type Buffer = any;
    declare const Buffer: any;
    declare const Bun: any;
    declare const process: any;
    declare namespace NodeJS {
      type ErrnoException = any;
      type Timeout = any;
    }
  '';

  untyped = ["omp/chat-look.ts" "omp/compact-eval.ts" "omp/work-fold.ts" "secrets/omp-secret.ts"];

  treeChecks = {
    ts = files: let
      farm = pkgs.linkFarm "ts" (lib.mapAttrsToList (name: text: {
          inherit name;
          path = pkgs.writeText (baseNameOf name) text;
        })
        files);
      tsc = flags: names: "${lib.getExe' pkgs.typescript "tsc"} --noEmit --strict false --skipLibCheck --allowImportingTsExtensions --preserveSymlinks --target es2022 --module esnext --moduleResolution bundler --lib es2023,dom ${flags}${ambient} ${lib.concatMapStringsSep " " (name: "${farm}/${name}") names}\n";
    in
      tsc "" (lib.subtractLists untyped (lib.attrNames files)) + tsc "--noCheck " untyped;
  };

  runner = pkgs.writeText "codec-runner.nix" ''
    candidate: let
      result = (builtins.getFlake "path:${inputs.self}").lib.lint.convert (builtins.fromJSON (builtins.readFile candidate));
    in
      result // {reason = result.reason (import (builtins.toFile "data.nix" result.nix));}
  '';

  jq = lib.getExe pkgs.jq;

  config = (pkgs.formats.toml {}).generate "strictix.toml" {
    codecs = lib.mapAttrs (_: c: {inherit (c) extensions;} // lib.optionalAttrs (c ? generator) {inherit (c) generator;}) codecs;
    lint = {
      schema = schema "finix" (lib.concatMap (host: lib.optionAttrSetToDocList host.options) (builtins.attrValues hosts));
      enabled = ["unused-option" "never-enabled-option" "constant-option" "duplicate-definitions" "singleton-attrset" "singleton-list" "templated-bindings" "scattered-documentation" "unformatted-file" "wrapped-prose" "repeated-dynamic-path" "repeated-let-value" "per-system-input-lookup"];
      generated = ["modules/hosts/steam-frame/beat-saber/beatmods.json"];
      disabled = ["hand-maintained-data-file" "codec-candidate"];
      constant-option = {
        readers = 3;
        defined = lib.unique (lib.concatMap (host: map (o: lib.showOption o.loc) (lib.filter (o: lib.any (file: lib.hasPrefix "${inputs.self}" (toString file) || toString file == "<unknown-file>") o.declarations && o.definitionsWithLocations != []) (lib.collect lib.isOption host.options))) (builtins.attrValues hosts));
      };
      duplicate-definitions.min-leaves = 6;
      flake-input-without-nixpkgs-follows.allow = [
        "cudaterm"
        "silva"
        "oh-my-fx"
        "oh-my-pi"
        "autolith"
        "emeraldian"
        "tomoe"
        "mado"
        "frame-charge"
        "steam-frame-nixos"
        "finix"
        "nixpkgs-librewolf"
      ];
      machine-local-default.allow = ["/home/steamos"];
      per-system-input-lookup.argument = "inputPackages";
      singleton-attrset.exempt = ["flake.nix"];
      singleton-list.exempt = ["flake.nix"];
      templated-bindings.exempt = ["flake.nix"];
      unformatted-file.command = "${lib.getExe inputPackages.alejandra.default} --quiet -";
    };
    schemas = {
      "modules/hosts/android-phone" = schema "droid" (lib.optionAttrSetToDocList droid.options);
      "modules/hosts/steam-frame" = "";
      "modules/hosts/shared.nix" = "";
      "omp-box" = "";
      "modules/lint.nix" = "";
    };
  };
in {
  inherit convert glslGate;

  app = pkgs.writeShellScriptBin "lint" ''
    command=''${1:-check}
    [ $# -gt 0 ] && shift
    [ "$command" = fix ] || exec ${strictix} "$command" "$@" --config ${config}
    set -euo pipefail
    scope=()
    dry=
    for arg in "$@"; do
      if [ "$arg" = --dry-run ]; then dry=1; else scope+=("$arg"); fi
    done
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    diagnose() {
      ${strictix} check --format json "''${scope[@]}" --config ${config} > "$work/diags.json" 2> "$work/err" || true
      if ! ${jq} -e .files "$work/diags.json" > /dev/null 2>&1; then
        cat "$work/err" >&2
        exit 2
      fi
    }
    diagnose
    ${strictix} fix "$@" --config ${config} || true
    [ -z "$dry" ] || exit 0
    diagnose
    ${jq} -c '.files[] | .path as $file | .diagnostics[] | select(.code == "codec-candidate") | .codec + {file: $file}' "$work/diags.json" > "$work/candidates"
    n=0
    touched=()
    while IFS= read -r c; do
      n=$((n + 1))
      get() { ${jq} -r ".$1 // empty" <<<"$c"; }
      file=$(get file)
      start=$(get replace.start)
      end=$(get replace.end)
      label="$file:$start $(get id) $(get kind)"
      data=
      target=
      datafile=
      if [ "$(get kind)" = text ]; then
        tail -c +$((start + 1)) "$file" | head -c $((end - start)) > "$work/$n.slice.nix"
        if ! nix eval --impure --raw --file "$work/$n.slice.nix" > "$work/$n.txt" 2> "$work/$n.err"; then
          echo "withheld $label: $(grep -m1 'error:' "$work/$n.err")"
          continue
        fi
      elif [ "$(get loader)" = lines ]; then
        target=$(get target)
        datafile=$target
        data=$(realpath -m --relative-to="$(dirname "$file")" "$datafile")
        case $data in ../*) ;; *) data=./$data ;; esac
        label="$label $target"
        if ! nix eval --impure --raw --expr "builtins.concatStringsSep \"\" (map (line: line + \"\n\") (import $(realpath "$target")))" > "$work/$n.txt" 2> "$work/$n.err"; then
          echo "withheld $label: $(grep -m1 'error:' "$work/$n.err")"
          continue
        fi
      else
        target=$(get target)
        cp "$target" "$work/$n.txt"
        name=$(basename "$target")
        datafile=$(dirname "$target")/''${name%.*}.data.nix
        data=$(realpath -m --relative-to="$(dirname "$file")" "$datafile")
        case $data in ../*) ;; *) data=./$data ;; esac
        label="$label $target"
        if [ -e "$datafile" ]; then
          echo "withheld $label: $datafile already exists"
          continue
        fi
        touch "$work/claims"
        claimed=$(${jq} -Rr --arg d "$datafile" 'split("\t") | select(.[0] == $d) | .[1]' "$work/claims" | head -n1)
        if [ -n "$claimed" ] && [ "$claimed" != "$target" ]; then
          echo "withheld $label: $datafile is also the destination for $claimed"
          continue
        fi
      fi
      extra=()
      if [[ " ${lib.concatStringsSep " " importers} " == *" $(get id) "* ]]; then
        input=$work/$n.txt
        [ "$(get loader)" = lines ] && input=$target
        if ! ${strictix} import "$(get id)" "$input" > "$work/$n.nix" 2> "$work/$n.err"; then
          echo "withheld $label: $(cat "$work/$n.err")"
          continue
        fi
        extra=(--rawfile nix "$work/$n.nix")
      fi
      ${jq} --rawfile text "$work/$n.txt" --arg data "$data" "''${extra[@]}" '. + $ARGS.named' <<<"$c" > "$work/$n.json"
      if ! nix eval --impure --json --expr "import ${runner} $work/$n.json" > "$work/$n.out" 2> "$work/$n.err"; then
        echo "withheld $label: $(grep -m1 'error:' "$work/$n.err")"
        continue
      fi
      reason=$(${jq} -r '.reason // empty' "$work/$n.out")
      if [ -n "$reason" ]; then
        echo "withheld $label: $reason"
        continue
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$file" "$start" "$end" "$n" "''${target:-}" "''${datafile:-}" >> "$work/accepted"
      [ -n "$datafile" ] && printf '%s\t%s\n' "$datafile" "$target" >> "$work/claims"
      echo "converted $label"
    done < "$work/candidates"
    if [ -s "$work/accepted" ]; then
      while IFS=$'\t' read -r file start end n target datafile; do
        if [ -n "$datafile" ]; then
          ${jq} -j .nix "$work/$n.out" > "$datafile"
          [ "$target" = "$datafile" ] || printf '%s\n' "$target" >> "$work/sources"
          touched+=("$datafile")
        fi
        { head -c "$start" "$file"; ${jq} -j .replacement "$work/$n.out"; tail -c +$((end + 1)) "$file"; } > "$work/splice"
        cat "$work/splice" > "$file"
        touched+=("$file")
      done < <(sort -t$'\t' -k1,1 -k2,2nr "$work/accepted")
      nix fmt -- "''${touched[@]}"
      if [ -s "$work/sources" ]; then
        sort -u "$work/sources" | while read -r target; do
          users=$(grep -rIlF --exclude-dir=.git -e "$(basename "$target")" . | grep -vxF "./$target" || true)
          if [ -n "$users" ]; then
            echo "kept $target: still referenced by $(echo $users)"
          else
            rm -f "$target"
          fi
        done
      fi
    fi
    exec ${strictix} check "''${scope[@]}" --config ${config}
  '';

  codegen = pkgs.runCommand "codegen" {} ''
    ${lib.concatStrings (lib.concatLists (lib.mapAttrsToList (language: files: lib.mapAttrsToList (name: text: languageChecks.${language} (pkgs.writeText name text)) files) (removeAttrs rendered (lib.attrNames treeChecks))))}
    ${lib.concatStrings (lib.mapAttrsToList (language: check: check rendered.${language}) treeChecks)}
    touch $out
  '';

  check = pkgs.runCommand "strictix" {} ''
    cd ${inputs.self}
    ${strictix} check . --config ${config}
    touch $out
  '';
}
