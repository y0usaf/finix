{
  config,
  lib,
  pkgs,
  ...
}: let
  whichKeyOpenEntries = [
    {
      key = "T";
      label = "terminal";
      command = "$term";
    }
    {
      key = "F";
      label = "files";
      command = "$filemanager";
    }
    {
      key = "L";
      label = "launcher";
      command = "$launcher";
    }
    {
      key = "E";
      label = "editor";
      command = "$notepad";
    }
    {
      key = "I";
      label = "IDE";
      command = "$ide";
    }
    {
      key = "B";
      label = "browser";
      command = "$browser";
    }
    {
      key = "D";
      label = "Discord";
      command = "$discord";
    }
    {
      key = "S";
      label = "Steam";
      command = "steam";
    }
    {
      key = "O";
      label = "OBS";
      command = "$obs";
    }
  ];

  whichKey = "${pkgs.lua5_4}/bin/lua ${pkgs.writeText "hyprland-which-key.lua" ''
    local config = ${lib.generators.toLua {} {
      icon = 1;
      timeoutMs = 6500;
      colour = "rgba(111111dd)";
      commands = {
        hyprctl = "${pkgs.hyprland}/bin/hyprctl";
        lua = "${pkgs.lua5_4}/bin/lua";
        sleep = "${pkgs.coreutils}/bin/sleep";
      };
      groups.open = {
        title = "open";
        entries =
          map (entry: {
            key = lib.toLower entry.key;
            inherit (entry) label;
          })
          whichKeyOpenEntries;
      };
    }}
    local commands = config.commands or {}

    local function sh_quote(value)
        return "'" .. tostring(value):gsub("'", [['"'"']]) .. "'"
    end

    local function run(...)
        local parts = {}
        for _, arg in ipairs({ ... }) do
            parts[#parts + 1] = sh_quote(arg)
        end

        local ok, _, code = os.execute(table.concat(parts, " "))
        if ok == true or ok == 0 then return 0 end
        return tonumber(code) or 1
    end

    local function spawn(command)
        os.execute(command .. " >/dev/null 2>&1 &")
    end

    local function sleep(seconds)
        run(commands.sleep or "sleep", tostring(seconds))
    end

    local function state_path()
        local runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
        local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
        return runtime .. "/hyprland-which-key-" .. signature
    end

    local function read_file(path)
        local handle = io.open(path, "r")
        if not handle then return nil end
        local contents = handle:read("*a")
        handle:close()
        return contents
    end

    local function write_file(path, contents)
        local handle = io.open(path, "w")
        if not handle then return end
        handle:write(contents)
        handle:close()
    end

    local function clear_state()
        os.remove(state_path())
    end

    local function reset_submap()
        clear_state()
        run(commands.hyprctl or "hyprctl", "dispatch", "submap", "reset")
    end

    local function format_group(group)
        local lines = { group.title or "which-key" }
        for _, entry in ipairs(group.entries or {}) do
            lines[#lines + 1] = string.format("  %-2s %s", entry.key or "?", entry.label or "")
        end
        return table.concat(lines, "\n")
    end

    local command = arg[1] or "open"
    if command == "reset" then
        reset_submap()
        return
    end

    if command == "timeout" then
        local token = arg[2] or ""
        sleep((config.timeoutMs or 6000) / 1000)
        if read_file(state_path()) == token then
            reset_submap()
        end
        return
    end

    local group_name = command
    local groups = config.groups or {}
    local group = groups[group_name]
    if not group then os.exit(1) end

    math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    local token = tostring(os.time()) .. "-" .. tostring(os.clock()) .. "-" .. tostring(math.random(1000000000))
    write_file(state_path(), token)

    local hyprctl = commands.hyprctl or "hyprctl"
    run(hyprctl, "dispatch", "submap", group_name)
    run(
        hyprctl,
        "notify",
        tostring(config.icon or 1),
        tostring(config.timeoutMs or 6000),
        config.colour or "rgba(111111dd)",
        format_group(group)
    )

    spawn(table.concat({
        sh_quote(commands.lua or "lua"),
        sh_quote(arg[0]),
        "timeout",
        sh_quote(token),
    }, " "))
  ''}";
  withSubmapReset = command: "${whichKey} reset; ${command}";

  whichKeyOpenBinds =
    lib.lists.flatten (map (entry: [
        ", ${entry.key}, exec, ${withSubmapReset entry.command}"
        "$mod, ${entry.key}, exec, ${withSubmapReset entry.command}"
      ])
      whichKeyOpenEntries)
    ++ [
      ", Escape, exec, ${whichKey} reset"
      "$mod, Escape, exec, ${whichKey} reset"
      ", Return, exec, ${whichKey} reset"
      ", BackSpace, exec, ${whichKey} reset"
    ];
  binds = lib.lists.flatten [
    [
      "$mod CTRL, G, togglegroup"
      "$mod CTRL, L, lockactivegroup, toggle"
      "$mod CTRL SHIFT, G, lockgroups, toggle"
      "$mod CTRL, J, changegroupactive, b"
      "$mod CTRL, K, changegroupactive, f"
      "$mod CTRL, H, moveoutofgroup"
      "$mod, comma, moveintogroup, l"
      "$mod, period, moveoutofgroup"
      "$mod, bracketleft, movewindoworgroup, l"
      "$mod, bracketright, movewindoworgroup, r"
    ]
    [
      "$mod, Q, killactive"
      "$mod, M, exit"
      "$mod, P, pseudo"
    ]
    [
      "$mod, F, fullscreen, 1"
      "$mod SHIFT, F, fullscreen"
      "$mod2, F, fullscreenstate, 0 2 toggle"
      "$mod, TAB, cyclenext"
      "$mod, space, layoutmsg, fit active"
      "$mod2, space, togglefloating"
      "$mod SHIFT, E, exit"
    ]
    [
      "$mod, T, exec, $term"
      "$mod, E, exec, $filemanager"
      "$mod2, R, exec, $launcher"
      "$mod, O, exec, ${whichKey} open"
      "$mod2 SHIFT, O, exec, $notepad"
      "$mod, R, layoutmsg, colresize +conf"
      "$mod, 1, exec, $ide"
      "$mod, 2, exec, $browser"
      "$mod, 3, exec, discord"
      "$mod, 4, exec, steam"
      "$mod, 5, exec, $obs"
    ]
    [
      "$mod, S, movecurrentworkspacetomonitor, +1"
    ]
    [
      "$mod, h, layoutmsg, focus l"
      "$mod, j, changegroupactive, b"
      "$mod, k, changegroupactive, f"
      "$mod, l, layoutmsg, focus r"
      "$mod, left, layoutmsg, focus l"
      "$mod, down, changegroupactive, b"
      "$mod, up, changegroupactive, f"
      "$mod, right, layoutmsg, focus r"
      "$mod SHIFT, h, layoutmsg, swapcol l"
      "$mod SHIFT, j, movegroupwindow, b"
      "$mod SHIFT, k, movegroupwindow, f"
      "$mod SHIFT, l, layoutmsg, swapcol r"
      "$mod SHIFT, left, layoutmsg, swapcol l"
      "$mod SHIFT, down, movegroupwindow, b"
      "$mod SHIFT, up, movegroupwindow, f"
      "$mod SHIFT, right, layoutmsg, swapcol r"
    ]
    (lib.lists.forEach (lib.range 1 9) (i: [
      "$mod2, ${toString i}, workspace, ${toString i}"
      "$mod2 SHIFT, ${toString i}, movetoworkspacesilent, ${toString i}"
    ]))
    [
      "Ctrl$mod2,Delete, exec, gnome-system-monitor"
      "$mod Shift, M, exec, shutdown now"
      "Ctrl$mod2Shift, M, exec, reboot"
      "Ctrl,Period,exec,smile"
    ]
    [
      "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
      "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
      "$mod, GRAVE, exec, hyprpicker | wl-copy"
    ]
    [
      "$mod SHIFT, C, exec, killall swaybg; for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
    ]
  ];
in {
  config =
    lib.mkIf config.user.ui.hyprland.enable {
      manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
        text =
          lib.mkAfter ''
            ${lib.concatMapStringsSep "
" (bind: "bind = ${bind}") binds}
            submap = open
            ${lib.concatMapStringsSep "
" (bind: "bind = ${bind}") whichKeyOpenBinds}
            submap = reset
            ${lib.concatMapStringsSep "
" (bind: "bindm = ${bind}") [
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
              ]}
          '';
      };
    };
}
