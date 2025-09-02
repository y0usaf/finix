{lib}: {
  # Shell script generator with proper escaping
  toShell = _: let
    inherit (lib) concatStringsSep escapeShellArg;
    inherit (builtins) typeOf;

    renderLine = line:
      if typeOf line == "string"
      then line
      else if typeOf line.cmd or null == "string"
      then "${line.cmd} ${concatStringsSep " " (map escapeShellArg (line.args or []))}"
      else toString line;
  in
    lines: concatStringsSep "\n" (map renderLine lines);
}
