{lib}: let
  declarations = set:
    if builtins.isList set
    then set
    else throw "cssSource: `set` must be a list of [property value] pairs, because declaration order matters in CSS";

  declaration = pair: "  ${builtins.elemAt pair 0}: ${builtins.elemAt pair 1};\n";

  indent = text: lib.concatMapStringsSep "\n" (line: lib.optionalString (line != "") "  ${line}") (lib.splitString "\n" text);

  node = n:
    if n ? select
    then "${n.select} {\n${lib.concatMapStrings declaration (declarations n.set)}}"
    else if n ? rules
    then "${n.at} {\n${indent (nodes n.rules)}\n}"
    else "${n.at};";

  nodes = lib.concatMapStringsSep "\n\n" node;
in {
  cssSource = list: "${nodes list}\n";
}
