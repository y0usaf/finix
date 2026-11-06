{
  add,
  del,
  file,
  hunk,
  ...
}: [
  (file "src/shell/invocation.zig" [
    (hunk 37 [
      "    script: []const u8,"
      "    arg_zero: []const u8,"
      "    positionals: []const []const u8 = &.{},"
      (add "    login: bool = false,")
      "};"
      ""
      "pub const ScriptFile = struct {"
    ])
    (hunk 113 [
      "            .script = args[index],"
      "            .arg_zero = if (operands.len == 0) args[0] else operands[0],"
      "            .positionals = if (operands.len <= 1) &.{} else operands[1..],"
      (add "            .login = login,")
      "        } };"
      "    }"
      "    if (!standard_input and index < args.len) {"
    ])
  ])
  (file "src/app.zig" [
    (hunk 28 [
      "    state_options: shell.state.Options,"
      "    arg_zero: []const u8,"
      "    positionals: []const []const u8,"
      (add "    login: bool = false,")
      "};"
      ""
      "pub fn run("
    ])
    (hunk 87 [
      "                .state_options = command.options,"
      "                .arg_zero = command.arg_zero,"
      "                .positionals = command.positionals,"
      (add "                .login = command.login,")
      "            }, src);"
      "        },"
      "        .script_file => |script| {"
    ])
    (hunk 133 [
      "    try shell.builtin.initializeSignals(&sh);"
      "    sh.setFunctionAutoload(autoloadRushFunction);"
      ""
      (del "    if (options.state_options.interactive) {")
      (add "    if (options.state_options.interactive or options.login) {")
      "        var source_id = src.id +% 1;"
      (del "        if (try startup.source(&sh, &source_id, false)) |status| return status;")
      (add "        if (try startup.source(&sh, &source_id, options.login)) |status| return status;")
      "    }"
      ""
      "    const evaluated = sh.evalSource(src) catch |err| {"
    ])
  ])
]
