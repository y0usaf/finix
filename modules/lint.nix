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

  config = (pkgs.formats.toml {}).generate "strictix.toml" {
    lint = {
      schema = schema "finix" (lib.concatMap (host: lib.optionAttrSetToDocList host.options) (builtins.attrValues hosts));
      enabled = ["unused-option" "never-enabled-option" "constant-option" "duplicate-definitions" "singleton-attrset" "singleton-list" "templated-bindings" "scattered-documentation" "unformatted-file" "wrapped-prose" "repeated-dynamic-path" "repeated-let-value" "per-system-input-lookup"];
      generated = ["modules/hosts/steam-frame/beat-saber/beatmods.json"];
      disabled = ["hand-maintained-data-file"];
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
  inherit glslGate;

  app = pkgs.writeShellScriptBin "lint" ''
    command=''${1:-check}
    shift || true
    [ "$command" = fix ] || exec ${strictix} "$command" "$@" --config ${config}
    set -euo pipefail
    ${strictix} fix "$@" --config ${config} || true
    exec ${strictix} import "$@"
  '';

  check = pkgs.runCommand "strictix" {} ''
    cd ${inputs.self}
    ${strictix} check . --config ${config}
    touch $out
  '';
}
