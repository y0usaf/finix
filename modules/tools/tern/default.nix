{
  config,
  lib,
  pkgs,
  flakeInputs,
  generators,
  ...
}: let
  version = "0.9.14";

  wpewebkit = import ../../../pkgs/wpewebkit.nix {inherit pkgs;};

  src = pkgs.requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    hashMode = "flat";
    hash = "sha256-BCiqLpp82q3qxoYW0GYEXutcNI1ebYD2bHFfGziJNZw=";
    message = ''
      Tern ${version} is a closed-beta build behind a Stencil account. Sign in
      at https://stencil.so/tern, download Tern-${version}-linux-x86_64.tar.gz
      from the browser session that is signed in, then:

        nix-store --add-fixed sha256 Tern-${version}-linux-x86_64.tar.gz

      A new build needs the version and the hash above.
    '';
  };

  tern = pkgs.stdenv.mkDerivation {
    pname = "tern";
    inherit version src;

    nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper];
    buildInputs = [pkgs.stdenv.cc.cc.lib];
    runtimeDependencies = [
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.vulkan-loader
      pkgs.libglvnd
      pkgs.linux-pam
      pkgs.webkitgtk_4_1
      pkgs.libwpe-fdo
      wpewebkit
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 tern $out/bin/tern
      wrapProgram $out/bin/tern --prefix GIO_EXTRA_MODULES : ${pkgs.glib-networking}/lib/gio/modules --prefix PATH : ${lib.makeBinPath [pkgs.bubblewrap]}
      runHook postInstall
    '';

    meta = {
      description = "Tern, Stencil's GPU multiplexing terminal";
      homepage = "https://stencil.so/tern";
      mainProgram = "tern";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  };

  registration = pkgs.runCommand "tern-registration" {} ''
    export HOME=$TMPDIR/home
    export XDG_DATA_HOME=$HOME/.local/share
    export XDG_CONFIG_HOME=$HOME/.config
    export XDG_CACHE_HOME=$HOME/.cache
    export XDG_STATE_HOME=$HOME/.local/state
    mkdir -p "$HOME"
    ${tern}/bin/tern register > /dev/null

    install -d $out/share
    cp -r "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/icons" $out/share/
    substituteInPlace $out/share/applications/*.desktop --replace-fail "/bin/.tern-wrapped" "/bin/tern"
    printf 'Path=%s\n' ${config.user.homeDirectory} >> $out/share/applications/so.stencil.tern.desktop
  '';

  package = pkgs.symlinkJoin {
    name = "tern-${version}";
    paths = [tern registration];
  };

  cmusTsp = pkgs.writeScriptBin "cmus-tsp" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3.withPackages (ps: [ps.numpy])}/bin/python3 ${config.user.homeDirectory}/dev/developing/tern-cmus/cmus-tsp "$@"
  '';

  ocean = "${pkgs.kdePackages.ocean-sound-theme}/share/sounds/ocean/stereo";

  tuturuClip = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/tuturu_1.mp3";
    hash = "sha256-cFN85xl8zdwaziqtnrzakuC+1pSAAU9AUbHz1HPrdEA=";
  };

  tuturuLevel = -34;

  tuturuSounds = pkgs.runCommand "tern-tuturu-sounds" {nativeBuildInputs = [pkgs.ffmpeg-headless pkgs.gawk];} ''
    mkdir $out
    level() {
      ffmpeg -nostats -loglevel error -i "$2" -af "''${3:-anull}" shaped.wav
      mean=$(ffmpeg -nostats -i shaped.wav -af volumedetect -f null - 2>&1 | awk '/mean_volume/ {print $(NF-1)}')
      ffmpeg -nostats -loglevel error -i shaped.wav -af "volume=$(awk -v m="$mean" 'BEGIN {print ${toString tuturuLevel} - m}')dB" -c:a libvorbis "$out/$1.ogg"
      rm shaped.wav
    }
    level alert ${ocean}/dialog-question.oga
    level yield ${tuturuClip} "aresample=48000,pan=mono|c0=0.5*c0+0.5*c1,highpass=f=80,equalizer=f=220:t=q:w=1:g=3,equalizer=f=650:t=q:w=1:g=-4,equalizer=f=3200:t=q:w=1:g=9,highshelf=f=6000:g=8,acompressor=threshold=-24dB:ratio=4:attack=3:release=60:makeup=2,alimiter=limit=0.9,asplit[near][far];[near]equalizer=f=150:t=q:w=1:g=4[right];[far]lowpass=f=2500,volume=-12dB,adelay=delays=22S:all=1[left];[right][left]join=inputs=2:channel_layout=stereo:map=0.0-FR|1.0-FL"
    level done ${ocean}/outcome-success.oga
  '';

  tuturu = {
    ".local/state/tern/plugin-data/tuturu/sounds.toml".text = ''
      alert = "${tuturuSounds}/alert.ogg"
      yield = "${tuturuSounds}/yield.ogg"
      done = "${tuturuSounds}/done.ogg"
      only_unfocused = true
      min_seconds = 30
    '';
  };

  pluginPaths = {
    "plugins/cmus.path" = lib.fileContents ./config/plugins/cmus.path;
    "plugins/ekko.path" = "${flakeInputs.tern-ekko}";
    "plugins/nix-fail.path" = lib.fileContents ./config/plugins/nix-fail.path;
  };

  configFiles =
    {
      "carly/HEARTBEAT.md" = generators.sourceFile "HEARTBEAT.md" (generators.markdown.render (({
          blank,
          comment,
          heading,
          ...
        }: [
          (heading 1 "Heartbeat")
          blank
          (comment "\nCarly reads this checklist on every heartbeat (every 30 minutes by default, Settings › Carly) and speaks up only when something needs you. While it holds nothing but headings and comments, no heartbeat runs.\n\nExamples:\n- Tell me when a long build or test run in any terminal finishes or fails.\n- If a pane shows a merge conflict or a crashed dev server, say which.\n- Remind me of anything I asked you to follow up on today.\n")
        ])
        generators.markdown));
      "carly/MEMORY.md" = generators.sourceFile "MEMORY.md" (generators.markdown.render (({
          blank,
          bullets,
          code,
          comment,
          heading,
          strong,
          ...
        }: [
          (heading 1 "Memory")
          blank
          (comment " Durable facts and decisions worth knowing at the start of every conversation: projects, where things live, how the user works. Keep it short and current; details belong in the daily notes (memory/YYYY-MM-DD.md). ")
          blank
          (bullets [
            [(strong "DECK") " (cards in Tern, the way his Ekko does them) lives in the ekko window plugin at " (code "~/dev/developing/tern-ekko") " (" (code "window.luau") ", " (code "ekko.css") ", " (code "plugin.toml") ") — a plain directory, not a git repo, so edits need no commit. Cards are Tern tabs (Vertical), Ctrl-J/K flip them, and the plugin owns the status line: deck position " (code "N/M name ●") ", cpu/mem/gpu/vram/load/clock, and a Cards picker (" (code "plugin.ekko.cards") ", Ctrl-P c). Reload with " (code "tern plugin reload ekko") "; plugin stylesheets reload only with the plugin (" (code "tern ctl css reload") " ignores them). The stats must self-start at load, because " (code "window_start") " does not run again on a reload."]
            ["Tern is a closed binary from build.stencil.so, installed by " (code "~/finix/modules/tools/tern/default.nix") " (0.9.14); plugin docs at docs.stencil.so/tern, layout guide at " (code "guides/layout.html") ". Its layout is fixed policy: the arrangement verbs are new_tab/split/focus/close/move/resize/tab — no placement verb, no rects."]
            ["His reference terminals are his own: Ekko (" (code "~/dev/maintaining/ekko") ", Common Lisp, gets its deck from " (code "place-panes") "/layout providers) and Cudaterm (" (code "~/dev/maintaining/cudaterm") ")."]
            ["Measured 2026-10-29: CSS moves a pane's box (front " (code "[349,0,2174,1388]") ", back " (code "[-3000,0,2174,1388]") ") but the PTY grid stays at its split size (95×63) — Tern sizes panes from its split math, not the DOM box, so CSS is chrome only and there is no in-window deck; parking reflows PTYs. Untested lead: picture-in-picture panes place in corners, dock to edges and can be hidden (\"Hide pictures in picture\") — worth testing whether a hidden PiP keeps its grid size."]
            ["Measuring habits that work: stub-load " (code "window.luau") " in the Lua VM (" (code "loadstring('return function(tern) ' .. src .. ' end')()") ") to unit-test handlers; " (code "tern ctl dump") " (~11 MB JSON, run inside a Tern pane) for DOM geometry; " (code "tern inspect --json") " for every pane's cols/rows; a scratch shell pane via " (code "cx.layout:split(target, dir, { command = 'sh' })") ". " (code "tern ctl state") " describes only the shown tab and calls the tab list " (code "decks") "; " (code "cx.layout:new_tab()") " returns the new pane id, not the tab id."]
            ["My own memory flush fails with " (code "No API key found for google-vertex") " (seen 2026-10-29 22:55); workspace writes still work."]
            [(strong "PR3544") " is a review of the tlc webhooks PR, checked out at " (code "/tmp/tlc") "."]
          ])
        ])
        generators.markdown));
      "carly/SOUL.md" = generators.sourceFile "SOUL.md" (generators.markdown.render (({
          blank,
          bullets,
          comment,
          heading,
          ...
        }: [
          (heading 1 "Carly")
          blank
          "You are Carly, the assistant who lives in the user's terminal. You are quick, warm and plain-spoken: a capable colleague at the next desk, not a butler and not a chatbot."
          blank
          (bullets [
            "Do the thing, then say what you did in a sentence. Skip preambles, apologies and offers of further help."
            "When unsure what they mean, ask one short question instead of guessing at something irreversible."
            "Never type a command that deletes, overwrites, pushes, deploys or spends money unless they asked for exactly that."
            "Their screens can hold secrets: use what you read to help, never repeat tokens or passwords back."
            "Have opinions when asked; keep them short."
          ])
          blank
          (comment " This file is Carly's. She may rewrite it as she learns how you like to work; you may too. ")
        ])
        generators.markdown));
      "carly/USER.md" = generators.sourceFile "USER.md" (generators.markdown.render (({
          blank,
          bullets,
          code,
          comment,
          heading,
          ...
        }: [
          (heading 1 "User")
          blank
          (comment " Stable facts and preferences about the user, written as directives (\"Prefers pnpm over npm\", \"Calls the main repo 'stencil'\"). Supersede a line in place when it changes; don't append a contradiction. ")
          blank
          (bullets [
            ["Works in Tern but measures it against his own terminals, Ekko (" (code "~/dev/maintaining/ekko") ", Common Lisp) and Cudaterm; wants Tern to do Ekko's deck layout."]
            "Hates jank: a PTY reflowing (SIGWINCH) when a pane or card changes is unacceptable. Prove claims with a measurement, not an argument."
            ["Runs several omp/rush agent tabs at once in " (code "/tmp") ", each named with a glyph prefix and its task (" (code "󰕮 DECK: …") ", " (code "󰇷 PR3544: …") "), and expects agents to be told exactly what to do next."]
            "Terse, candid, pushes back on hand-waving; lead with the result, skip preambles."
            "Plays with terminal UI for its own sake (deck layouts, sidebar chrome, status-line stats), so small reversible experiments are welcome."
          ])
        ])
        generators.markdown));
      "carly/memory/2026-10-29.md" = generators.sourceFile "2026-10-29.md" (generators.markdown.render (({
          blank,
          bullets,
          code,
          em,
          heading,
          strong,
          ...
        }: [
          (heading 1 "2026-10-29")
          blank
          (bullets [
            ["23:00 DECK chat (tab 1 agent, pane 433791696898) is idle after its last turn: deck = Tern tabs as cards, Ctrl-J/K next/prev card, system stats in the status line via the ekko window plugin (" (code "~/dev/developing/tern-ekko/window.luau") ", ekko.css — not a git repo). Its one open question to the user: trim Tern's sidebar to just the card list (hide " (code "button.nav-head") " session group line and/or " (code "div.tn-vt-find") " Filter tabs). No plugin handler failures in the log since 21:43. Mistake of mine: " (code "cx.session:focused()") " returns a PaneInfo, not a pane id; passing it as " (code "cx.layout:split()") "'s target launched a duplicate " (code "rush") " agent that copied the PR3544 session into a new file. Killed the pane; the real PR3544 session (pane 618475290644) is untouched, no stray text in the copy. Remaining residue: " (code ".omp/agent/sessions/-tmp/2026-10-30T02-58-23-697Z_*") " (empty-ish copy, 962 KB) and its dir."]
            ["23:07 Deck work (ekko plugin " (code "~/dev/developing/tern-ekko/window.luau") ", now 575 lines, no git here): added a " (strong "deck position indicator") " to the native status line — " (code "N/M <card name> ●") " where the name is the tab's user-given name else its title clipped to 18 chars, warning tone and a busy dot while a command runs, clickable (" (code "command = plugin.ekko.cards") ") — plus a " (strong "Cards picker") " (" (code "plugin.ekko.cards") ", Ctrl-P c, or click the indicator) listing every card with program, pane count and cwd; selecting focuses that card's block. Also made the system stats " (strong "self-start at plugin load") ": " (code "window_start") " does not fire on " (code "tern plugin reload") ", so the cpu/mem/gpu segments had silently vanished since my first reload. Verified: stub-loaded the plugin in the Lua VM (status formatter returns " (code "2/2 PR3544 ●") " + stats + nil for an unknown pane); live DOM width test through " (code "tern ctl dump") " in a scratch pane — the ekko status span went 113px → 425px with a 40-char marker → 253px with the real label, and the stats spans came back after the load-time tick. Scratch pane closed, scratch files deleted. Ceiling, again: Tern has no placement verb (Ekko's " (code "place-panes") " parks a card off-screen at full size); " (code "park") " collapses the split and reflows the PTY, which is the jank. Cards = tabs is the honest approximation. Found: " (code "settings.json") "'s " (code "\"ctrl+tab\": \"plugin.ekko.swap_sides\"") " is dropped — a Tern preset owns ctrl+tab (\"plugin bind left out: the preset binds these keys\"), so that bind never worked."]
            ["23:12 Answered \"why can't a plugin do the deck?\" by measuring it in a scratch tab (two " (code "sh") " panes, tab 674309865501, now closed; " (code "ekko.css") " restored from backup and plugin reloaded, nothing left behind): - With CSS " (code "section.tn-pane.on { position: fixed; left: 349px; width: 2174px; height: 1388px }") " and " (code "section.tn-pane.dim { left: -3000px; ... }") ", the pane " (strong "boxes") " obeyed (front [349,0,2174,1388], back [-3000,0,2174,1388], both visible=true) — but both " (strong "PTY grids stayed 95×63") ". Tern sizes a pane from its own split math, not from the DOM box, so CSS can move a pane but cannot give it a full-size grid or keep a full-size card off-screen. The app only gives a full grid to panes in the tab's split tree, and everything in the tree is tiled; removing one from the tree is " (code "park") ", which reflows it on return. That single missing input is the deck. - " (code "tern ctl css reload") " reports " (code "{\"reloaded\":[],\"unchanged\":0}") " for an edited " (em "plugin") " stylesheet — plugin CSS needs " (code "tern plugin reload <id>") ". - " (code "tern inspect --json") " lists every pane in every tab with " (code "cols") "/" (code "rows") ", shown or not; " (code "tern ctl state") " only describes the " (em "shown") " tab of that window. - " (code "cx.layout:new_tab(launch, reveal)") " returns the new " (strong "pane") " id, not the tab id; " (code "cx.layout:split(target, dir, {command=...})") " is how to get a plain shell pane."]
          ])
        ])
        generators.markdown));
      "carly/memory/2026-10-30.md" = generators.sourceFile "2026-10-30.md" (generators.markdown.render (({
          blank,
          bullets,
          code,
          heading,
          ...
        }: [
          (heading 1 "2026-10-30")
          blank
          (bullets [
            ["04:04 - Conversation closed on the deck idea. Shipped today in " (code "~/dev/developing/tern-ekko/window.luau") ": status-line deck indicator (" (code "N/M name ●") ", clickable) + Cards picker (" (code "plugin.ekko.cards") ", Ctrl-P c), and a load-time tick so the cpu/mem/gpu stats survive " (code "tern plugin reload") ". Open follow-ups: (1) test whether a hidden picture-in-picture pane keeps its grid size — if yes, PiP is the deck primitive Tern lacks; (2) offered the two-column deck (second window on its own session, tomoe-tiled, ~900 MiB); (3) " (code "ctrl+tab") " in settings.json is dropped by a Tern preset, so it never worked; (4) the DECK agent still awaits his call on trimming Tern's sidebar header (hide " (code "button.nav-head") " and/or " (code "div.tn-vt-find") "); (5) leftover junk session copy " (code "~/.omp/agent/sessions/-tmp/2026-10-30T02-58-23-697Z_*") " from my bad split, still undeleted."]
          ])
        ])
        generators.markdown));
      "plugins/agent-tabs/plugin.toml" = ./config/plugins/agent-tabs/plugin.toml;
      "plugins/agent-tabs/window.luau" = ./config/plugins/agent-tabs/window.luau;
      "plugins/block-menu/plugin.toml" = ./config/plugins/block-menu/plugin.toml;
      "plugins/block-menu/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (({
          PickItem,
          WindowCx,
          blank,
          comment,
          dot,
          field,
          fn,
          for,
          if',
          ifElse,
          infix,
          ipairs,
          local,
          localFunction,
          nil,
          not,
          opt,
          return,
          rows,
          str,
          string,
          table,
          table',
          tern,
          type',
          typed,
          ...
        }: ({
          blocks,
          agents,
          launch,
          menu,
        }: [
          (comment "--!strict")
          blank
          (local blocks (rows (table [
            (table [(field "label" (str "Terminal")) (field "detail" (str "shell block")) (field "icon" (str "terminal")) (field "action" (str "new_shell_block"))])
            (table [(field "label" (str "Browser")) (field "detail" (str "web page")) (field "icon" (str "globe")) (field "action" (str "new_browser_block"))])
            (table [(field "label" (str "Git")) (field "detail" (str "status, commits")) (field "icon" (str "branch")) (field "action" (str "new_git_block"))])
            (table [(field "label" (str "Board")) (field "detail" (str "lanes and cards")) (field "icon" (str "kanban")) (field "action" (str "new_board_block"))])
            (table [(field "label" (str "Canvas")) (field "detail" (str "shapes and notes")) (field "icon" (str "canvas")) (field "action" (str "new_canvas_block"))])
            (table [(field "label" (str "Task manager")) (field "detail" (str "processes")) (field "icon" (str "list-checks")) (field "action" (str "new_task_manager_block"))])
            (table [(field "label" (str "Screen")) (field "detail" (str "remote display")) (field "icon" (str "monitor")) (field "action" (str "new_screen_block"))])
          ])))
          blank
          (local agents (rows (table [
            (table [(field "label" (str "omp")) (field "icon" (str "app-omp")) (field "command" (str "omp"))])
            (table [(field "label" (str "Claude Code")) (field "icon" (str "app-claude")) (field "command" (str "tern acp claude"))])
            (table [(field "label" (str "Codex")) (field "icon" (str "app-codex")) (field "command" (str "tern acp codex"))])
          ])))
          blank
          (localFunction launch [{cx = WindowCx;} {command = string;}] ({
            cx,
            command,
            placement,
            id,
            info,
          }: [
            (local placement [(dot cx "settings:get") (str "agent_placement")])
            (if' (infix [placement "==" (str "new_tab")]) [
              [(dot cx "layout:new_tab") (table [(field "command" command)])]
              return
            ])
            (local id [(dot cx "session:focused")])
            (local info (infix [id "and" [(dot cx "session:pane") id] "or" nil]))
            (if' (not info) [
              [(dot cx "layout:new_tab") (table [(field "command" command)])]
              return
            ])
            (if' (infix [placement "==" (str "replace_if_alone")]) ({
              tab,
              layout,
            }: [
              (local tab [(dot cx "session:tab_of") (dot info "pane")])
              (local layout (infix [tab "and" [(dot cx "session:layout") tab]]))
              (if' (infix [layout "and" (dot layout "root.pane")]) ({pane}: [
                (local pane [(dot cx "layout:split") (dot info "pane") (str "right") (table [(field "command" command)])])
                (if' pane [
                  [(dot cx "layout:close") (dot info "pane")]
                ])
                return
              ]))
            ]))
            [(dot cx "layout:split") (dot info "pane") (str "right") (table [(field "command" command)])]
          ]))
          blank
          (localFunction menu [{cx = WindowCx;}] ({
            cx,
            items,
            custom,
          }: [
            (local (typed items (table [PickItem])) (table []))
            (for [{_ = null;} {row = null;}] [ipairs blocks] ({
              _,
              row,
            }: [
              [
                (dot table' "insert")
                items
                (rows (table [
                  (field "label" (dot row "label"))
                  (field "detail" (dot row "detail"))
                  (field "group" (str "Blocks"))
                  (field "icon" (dot row "icon"))
                  (field "action" (dot row "action"))
                ]))
              ]
            ]))
            (for [{_ = null;} {row = null;}] [ipairs agents] ({
              _,
              row,
            }: [
              [
                (dot table' "insert")
                items
                (rows (table [
                  (field "label" (dot row "label"))
                  (field "group" (str "Agents"))
                  (field "icon" (dot row "icon"))
                  (field "command" (dot row "command"))
                ]))
              ]
            ]))
            (local custom [(dot cx "settings:get") (str "agents.custom")])
            (if' (infix [[type' custom] "==" (str "table")]) [
              (for [{_ = null;} {entry = null;}] [ipairs custom] ({
                _,
                entry,
                name,
                command,
              }: [
                (local name (infix [[type' entry] "==" (str "table") "and" (dot entry "name") "or" nil]))
                (local command (infix [[type' entry] "==" (str "table") "and" (dot entry "command") "or" nil]))
                (if' (infix [[type' name] "==" (str "string") "and" [type' command] "==" (str "string") "and" name "~=" (str "") "and" command "~=" (str "")]) [
                  [
                    (dot table' "insert")
                    items
                    (rows (table [
                      (field "label" name)
                      (field "group" (str "Agents"))
                      (field "icon" (str "puzzle"))
                      (field "command" command)
                    ]))
                  ]
                ])
              ]))
            ])
            [(dot table' "insert") items (table [(field "label" (str "Carly")) (field "group" (str "Agents")) (field "icon" (str "sparkle")) (field "action" (str "new_carly_block"))])]
            (for [{_ = null;} {block = null;}] [ipairs [(dot cx "session:block_types")]] ({
              _,
              block,
            }: [
              (if' (infix [(dot block "palette") "and" (dot block "kind") "~=" (str "canvas") "and" (dot block "kind") "~=" (str "tern.canvas")]) [
                [
                  (dot table' "insert")
                  items
                  (rows (table [
                    (field "label" (dot block "title"))
                    (field "detail" (dot block "kind"))
                    (field "group" (str "Plugins"))
                    (field "icon" (dot block "icon"))
                    (field "kind" (dot block "kind"))
                  ]))
                ]
              ])
            ]))
            [
              (rows (dot [(dot cx ":pick") (table [(field "items" items) (field "placeholder" (str "New block")) (field "icon" (str "plus")) (field "action" (str "create"))])] ":next"))
              (fn [{item = opt PickItem;} {_err = opt string;} {fresh = opt WindowCx;}] ({
                item,
                _err,
                fresh,
                next_cx,
              }: [
                (if' (not item) [
                  return
                ])
                (local next_cx (infix [fresh "or" cx]))
                (ifElse (dot item "command") [
                    [launch next_cx (dot item "command")]
                  ] (ifElse (dot item "kind") [
                      [(dot next_cx ":new_block") (dot item "kind")]
                    ] (if' (dot item "action") [
                      [(dot next_cx ":action") (dot item "action")]
                    ])))
              ]))
            ]
          ]))
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "new_block"))
              (field "title" (str "New block…"))
              (field "icon" (str "plus"))
              (field "keys" (table [(str "ctrl+n")]))
              (field "run" menu)
            ]))
          ]
        ]))
        generators.luau));
      "plugins/tab-order/plugin.toml" = ./config/plugins/tab-order/plugin.toml;
      "plugins/tab-order/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (({
          FocusEvent,
          TabEvent,
          TabInfo,
          WindowCx,
          assign,
          blank,
          comment,
          dot,
          fn,
          for,
          if',
          infix,
          ipairs,
          local,
          localFunction,
          nil,
          not,
          number,
          opt,
          return,
          str,
          tern,
          tuple,
          typed,
          ...
        }: ({
          last,
          previous,
          note,
          focused_tab,
          tab_info,
          place,
        }: [
          (comment "--!strict")
          blank
          (local (typed last (opt number)) nil)
          (local (typed previous (opt number)) nil)
          blank
          (localFunction note [{id = opt number;}] ({id}: [
            (if' (infix [id "and" id "~=" last]) [
              (assign previous last)
              (assign last id)
            ])
          ]))
          blank
          (localFunction focused_tab (typed [{cx = WindowCx;}] (opt number)) ({
            cx,
            pane,
          }: [
            (local pane [(dot cx "session:focused")])
            (return (infix [pane "and" [(dot cx "session:tab_of") pane] "or" nil]))
          ]))
          blank
          (localFunction tab_info (typed [{cx = WindowCx;} {id = number;}] (opt TabInfo)) ({
            cx,
            id,
          }: [
            (for [{_ = null;} {info = null;}] [ipairs [(dot cx "session:tabs")]] ({
              _,
              info,
            }: [
              (if' (infix [(dot info "id") "==" id]) [
                (return info)
              ])
            ]))
            (return nil)
          ]))
          blank
          (localFunction place [{cx = WindowCx;} {id = number;} {anchor = opt number;}] ({
            cx,
            id,
            anchor,
            info,
            at,
          }: [
            (if' (infix [(not anchor) "or" anchor "==" id]) [
              return
            ])
            (local info [tab_info cx id])
            (local at [tab_info cx anchor])
            (if' (infix [(not info) "or" (not at) "or" (dot info "session") "~=" (dot at "session")]) [
              return
            ])
            (if' (infix [(dot info "position") ">" (dot at "position") "+" 1]) [
              [(dot cx "layout:order_tab") id (infix [(dot at "position") "+" 1])]
            ])
          ]))
          blank
          [
            (dot tern "on")
            (str "window_start")
            (fn [{cx = WindowCx;}] ({cx}: [
              (assign [last previous] (tuple [nil nil]))
              [note [focused_tab cx]]
            ]))
          ]
          blank
          [
            (dot tern "on")
            (str "focus")
            (fn [{ev = FocusEvent;}] ({ev}: [
              [note (dot ev "tab")]
            ]))
          ]
          blank
          [
            (dot tern "timer")
            0
            (fn [{cx = opt WindowCx;}] ({cx}: [
              [note (infix [cx "and" [focused_tab cx]])]
            ]))
          ]
          blank
          [
            (dot tern "on")
            (str "tab_created")
            (fn [{ev = TabEvent;} {cx = WindowCx;}] ({
              ev,
              cx,
            }: [
              (if' (infix [[focused_tab cx] "~=" (dot ev "tab")]) [
                return
              ])
              [place cx (dot ev "tab") (infix [last "==" (dot ev "tab") "and" previous "or" last])]
            ]))
          ]
        ]))
        generators.luau));
      "plugins/tuturu/.gitignore" = ./config/plugins/tuturu/.gitignore;
      "plugins/tuturu/README.md" = generators.sourceFile "README.md" (generators.markdown.render (({
          blank,
          code,
          heading,
          link,
          strong,
          table,
          wrap,
          ...
        }: [
          (heading 1 "Tuturu")
          blank
          (wrap "A sound when something needs you: a pane's unseen alert (terminal bell, agent waiting or finished out of sight, exited program), an omp agent yielding its turn, or a long shell command finishing. Sounds never overlap, and one window's sound suppresses the same moment's in every other window.")
          blank
          (wrap ["Vendored from " (link "H4vC/tern-chime" "https://github.com/H4vC/tern-chime") " and kept here like the rest of " (code "modules/tools/tern/config/plugins") ": Tern copies this folder to " (code "~/.config/tern/plugins/tuturu") "."])
          blank
          (heading 2 "Sounds")
          blank
          (wrap [(code "~/finix/modules/tools/tern/default.nix") " builds the three sounds and writes " (code "~/.local/state/tern/plugin-data/tuturu/sounds.toml") " to name them:"])
          blank
          (table ["Trigger" "Sound"] [
            [[(code "alert") ": terminal bell, an agent waiting, a pane alert"] ["Plasma Ocean " (code "dialog-question")]]
            [[(code "yield") ": an omp agent finished its turn"] "Tuturu, at the right ear"]
            [[(code "done") ": a shell command that ran " (code "min_seconds")] ["Plasma Ocean " (code "outcome-success")]]
          ])
          blank
          (wrap ["Every sound is levelled to the same average loudness (" (code "chimeLevel") ", −34 dB), and the shipped " (code "sounds.toml") " names no files, so a missing override is silent. That file still carries the knobs: " (code "only_unfocused") ", " (code "min_seconds") "."])
          blank
          (wrap ["To change a sound, edit the build in " (code "default.nix") "; to try one by hand without a rebuild, name your own file in the plugin data folder's " (code "sounds.toml") "."])
          blank
          (heading 2 "Palette")
          blank
          (wrap [(strong "Tuturu: Mute / unmute") " (the status line shows " (code "tuturu muted") " while muted), " (strong "Tuturu: Play test sound") ", " (strong "Tuturu: Reload sounds") ", " (strong "Tuturu: Diagnose panes and agents") " (writes what it sees to " (code "<plugin data>/diagnose.txt") ")."])
        ])
        generators.markdown));
      "plugins/tuturu/plugin.toml" = ./config/plugins/tuturu/plugin.toml;
      "plugins/tuturu/scripts/play.vbs" = generators.sourceFile "play.vbs" (generators.vbs.render (({
          CreateObject,
          Err,
          Replace,
          WScript,
          assign,
          blank,
          call,
          comment,
          dim,
          dot,
          if',
          onErrorResumeNext,
          optionExplicit,
          set,
          str,
          ...
        }: ({
          sh,
          wav,
          cmd,
          code,
        }: [
          (comment "Chime hidden player launcher (Windows).")
          (comment "")
          (comment "Run with wscript.exe (a GUI-subsystem host: no console window of its own).")
          (comment "It runs PowerShell hidden (window style 0 from creation, so not even a")
          (comment "flash) and waits for playback. PowerShell is a console-subsystem program,")
          (comment "so spawning it directly pops a console box on every chime; -WindowStyle")
          (comment "Hidden only hides it after it appears.")
          (comment "")
          (comment "Usage: wscript.exe //Nologo play.vbs <wav-file>")
          (comment "Exit code is PowerShell's; it never shows an error dialog.")
          blank
          optionExplicit
          onErrorResumeNext
          blank
          (if' [(dot WScript "Arguments.Count") "=" 0] [
            (call (dot WScript "Quit") [1])
          ])
          blank
          (dim [sh wav cmd])
          (set sh (call CreateObject [(str "WScript.Shell")]))
          (if' [(dot Err "Number") "<>" 0] [
            (call (dot WScript "Quit") [1])
          ])
          blank
          (assign wav (call (dot WScript "Arguments") [0]))
          (assign wav (call Replace [wav (str "'") (str "''")]))
          (assign cmd [(str "powershell -NoProfile -NonInteractive -WindowStyle Hidden -Command \"(New-Object Media.SoundPlayer '") "&" wav "&" (str "').PlaySync()\"")])
          blank
          (dim [code])
          (assign code (call (dot sh "Run") [cmd 0 true]))
          (if' [(dot Err "Number") "<>" 0] [
            (call (dot WScript "Quit") [1])
          ])
          (call (dot WScript "Quit") [code])
        ]))
        generators.vbs));
      "plugins/tuturu/sounds.toml" = ./config/plugins/tuturu/sounds.toml;
      "plugins/tuturu/src/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (({
          AgentBlock,
          CommandFinishedEvent,
          PaneInfo,
          ProcessResult,
          StatusPaneInfo,
          StatusSegment,
          WindowCx,
          assign,
          blank,
          boolean,
          cast,
          comment,
          dot,
          field,
          fn,
          for,
          idx,
          if',
          ifElse,
          ifExpr,
          infix,
          len,
          local,
          localFunction,
          math,
          neg,
          nil,
          not,
          number,
          opt,
          os,
          pair,
          paren,
          pcall,
          proproblems,
          return,
          rows,
          str,
          string,
          table,
          table',
          tern,
          tonumber,
          tostring,
          trailing,
          tuple,
          type,
          type',
          typed,
          update,
          while,
          ...
        }: ({
          Config,
          TICK_MS,
          CONFIG_EVERY_TICKS,
          MIN_GAP_MS,
          CLAIM_WINDOW_S,
          SEP,
          DATA_SEP,
          DATA_CONFIG,
          PLUGIN_CONFIG,
          trim,
          strip_comment,
          unquote,
          default_config,
          is_absolute,
          resolve_path,
          parse_config,
          config,
          config_source,
          config_key,
          warned,
          read_config_file,
          load_config,
          snapshot_key,
          maybe_reload_config,
          is_muted,
          refresh_muted,
          claim_chime,
          spawn,
          linux_player,
          linux_probe_failed,
          linux_probing,
          linux_queue,
          LINUX_PLAYERS,
          linux_argv,
          probe_linux_player,
          warned_no_player,
          play_file,
          last_chime_at,
          chime,
          list_agents,
          alerts,
          agent_state,
          seeded,
          tick_count,
          tick_body,
          tick,
          startup_problems,
        }: [
          (comment "--!strict")
          (comment "-- Tuturu: a sound when a pane raises an unseen alert, an agent yields to you,")
          (comment "-- or a long shell command finishes.")
          (comment "--")
          (comment "-- Triggers (all for panes you are not looking at, unless only_unfocused=false):")
          (comment "--   alert  a pane's unseen-alert flag rises: a terminal bell, an agent that")
          (comment "--          finished or is waiting out of sight, or a pane whose program")
          (comment "--          exited. Tern shows one alert per pane until you look at it, so a")
          (comment "--          second bell while the flag stands chimes nothing new.")
          (comment "--   yield  an agent block leaves \"working\" for \"idle\": its turn is done and")
          (comment "--          control is back with you. (working -> \"waiting_input\" plays the")
          (comment "--          alert sound instead: it needs you, not just your attention.)")
          (comment "--   done   a shell command ran longer than min_seconds and finished.")
          (comment "--")
          (comment "-- Chimes never overlap: simultaneous events share one chime, and a chime in")
          (comment "-- one window suppresses the same moment's chime in every other window.")
          (comment "--")
          (comment "-- Configuration is sounds.toml in the plugin folder (ships with defaults) or")
          (comment "-- <plugin data>/sounds.toml, which wins when present so a reinstall keeps")
          (comment "-- your sounds. It is re-read every few seconds; no reload needed.")
          blank
          (type Config (rows (table [
            (field "sounds" (table [(pair string string)]))
            (field "only_unfocused" boolean)
            (field "min_seconds" number)
          ])))
          blank
          (local TICK_MS 250)
          (trailing (local CONFIG_EVERY_TICKS 20) "-- re-read sounds.toml about every 5 s")
          (trailing (local MIN_GAP_MS 500) "-- chimes never overlap")
          (trailing (local CLAIM_WINDOW_S 2) "-- cross-window dedup: one chime per moment")
          blank
          (local SEP (ifExpr [(infix [(dot tern "runtime.os") "==" (str "windows")]) (str "\\") (str "/")]))
          (local DATA_SEP (infix [(dot tern "plugin.data") ".." SEP]))
          (local DATA_CONFIG (infix [DATA_SEP ".." (str "sounds.toml")]))
          (local PLUGIN_CONFIG (infix [(dot tern "plugin.dir") ".." SEP ".." (str "sounds.toml")]))
          blank
          (comment "-- Config ----------------------------------------------------------------------------------")
          blank
          (localFunction trim (typed [{s = string;}] string) ({s}: [
            (return (paren [(dot string "gsub") s (str "^%s*(.-)%s*$") (str "%1")]))
          ]))
          blank
          (comment "-- Cut a `#` comment, keeping `#` inside quotes.")
          (localFunction strip_comment (typed [{line = string;}] string) ({
            line,
            in_single,
            in_double,
            i,
          }: [
            (local in_single false)
            (local in_double false)
            (local i 1)
            (while (infix [i "<=" (len line)]) ({c}: [
              (local c [(dot string "sub") line i i])
              (ifElse (infix [c "==" (str "\\") "and" (infix [in_single "or" in_double])]) [
                  (update "+=" i 2)
                ] (ifElse (infix [c "==" (str "'") "and" (not in_double)]) [
                    (assign in_single (not in_single))
                    (update "+=" i 1)
                  ] (ifElse (infix [c "==" (str "\"") "and" (not in_single)]) [
                      (assign in_double (not in_double))
                      (update "+=" i 1)
                    ] (ifElse (infix [c "==" (str "#") "and" (not in_single) "and" (not in_double)]) [
                        (return [(dot string "sub") line 1 (infix [i "-" 1])])
                      ] [
                        (update "+=" i 1)
                      ]))))
            ]))
            (return line)
          ]))
          blank
          (comment "-- A quoted value without its quotes, or nil when not quoted. Only the")
          (comment "-- matching quote and the backslash unescape, so Windows paths work as-is")
          (comment "-- in double quotes (`\"C:\\sounds\\ping.wav\"` needs no doubling).")
          (localFunction unquote (typed [{s = string;}] (opt string)) ({
            s,
            first,
            inner,
          }: [
            (if' (infix [(len s) "<" 2]) [
              (return nil)
            ])
            (local first [(dot string "sub") s 1 1])
            (if' (infix [first "~=" (str "\"") "and" first "~=" (str "'")]) [
              (return nil)
            ])
            (if' (infix [[(dot string "sub") s (-1)] "~=" first]) [
              (return nil)
            ])
            (local inner [(dot string "sub") s 2 (-2)])
            (ifElse (infix [first "==" (str "\"")]) [
                (assign inner [(dot string "gsub") inner (str "\\\"") (str "\"")])
                (assign inner [(dot string "gsub") inner (str "\\\\") (str "\\")])
              ] [
                (assign inner [(dot string "gsub") inner (str "\\'") (str "'")])
              ])
            (return inner)
          ]))
          blank
          (localFunction default_config (typed [] Config) ({dir}: [
            (local dir (infix [(dot tern "plugin.dir") ".." SEP ".." (str "sounds")]))
            (return (rows (table [
              (field "sounds" (rows (table [
                (field "alert" (infix [dir ".." SEP ".." (str "alert.wav")]))
                (field "yield" (infix [dir ".." SEP ".." (str "yield.wav")]))
                (field "done" (infix [dir ".." SEP ".." (str "done.wav")]))
              ])))
              (field "only_unfocused" true)
              (field "min_seconds" 30)
            ])))
          ]))
          blank
          (localFunction is_absolute (typed [{p = string;}] boolean) ({p}: [
            (if' (infix [[(dot string "sub") p 1 1] "==" (str "/")]) [
              (return true)
            ])
            (return (infix [[(dot string "match") p (str "^[A-Za-z]:[\\/]")] "~=" nil "or" [(dot string "sub") p 1 2] "==" (str "\\\\")]))
          ]))
          blank
          (localFunction resolve_path (typed [{p = string;} {base = string;}] string) ({
            p,
            base,
          }: [
            (if' (infix [[(dot string "sub") p 1 1] "==" (str "~")]) ({home}: [
              (local home (infix [[(dot tern "getenv") (str "HOME")] "or" [(dot tern "getenv") (str "USERPROFILE")] "or" (str "")]))
              (if' (infix [home "~=" (str "")]) [
                (assign p (infix [home ".." [(dot string "sub") p 2]]))
              ])
            ]))
            (if' [is_absolute p] [
              (return p)
            ])
            (return (infix [base ".." SEP ".." p]))
          ]))
          blank
          (localFunction parse_config (typed [{text = string;} {base = string;}] (tuple [Config (table [string])])) ({
            text,
            base,
            config,
            problems,
          }: [
            (local config [default_config])
            (local (typed problems (table [string])) (table []))
            (for [{raw = null;}] [(dot string "gmatch") text (str "[^\r\n]+")] ({
              raw,
              line,
            }: [
              (local line [trim [strip_comment raw]])
              (if' (infix [line "~=" (str "")]) ({
                key,
                value,
              }: [
                (local [key value] [(dot string "match") line (str "^([A-Za-z_][%w_]*)%s*=%s*(.-)%s*$")])
                (ifElse (infix [key "==" nil "or" value "==" nil "or" value "==" (str "")]) [
                    [(dot table' "insert") problems (infix [(str "Skipping line: ") ".." line])]
                  ] (ifElse (infix [key "==" (str "alert") "or" key "==" (str "yield") "or" key "==" (str "done")]) ({quoted}: [
                      (local quoted [unquote value])
                      (ifElse (infix [quoted "==" nil]) [
                          [(dot table' "insert") problems (infix [key ".." (str ": expected a quoted path, got ") ".." value])]
                        ] (ifElse (infix [quoted "==" (str "")]) [
                            (assign (idx (dot config "sounds") key) (str ""))
                          ] [
                            (assign (idx (dot config "sounds") key) [resolve_path quoted base])
                          ]))
                    ]) (ifElse (infix [key "==" (str "only_unfocused")]) [
                        (ifElse (infix [value "==" (str "true")]) [
                            (assign (dot config "only_unfocused") true)
                          ] (ifElse (infix [value "==" (str "false")]) [
                              (assign (dot config "only_unfocused") false)
                            ] [
                              [(dot table' "insert") problems (infix [(str "only_unfocused: expected true or false, got ") ".." value])]
                            ]))
                      ] (ifElse (infix [key "==" (str "min_seconds")]) ({n}: [
                          (local n [tonumber value])
                          (ifElse (infix [n "==" nil "or" n "<" 0]) [
                              [(dot table' "insert") proproblems (infix [(str "min_seconds: expected seconds >= 0, got ") ".." value])]
                            ] [
                              (assign (dot config "min_seconds") n)
                            ])
                        ]) [
                          [(dot table' "insert") problems (infix [(str "Unknown key: ") ".." key])]
                        ]))))
              ]))
            ]))
            (return (tuple [config problems]))
          ]))
          blank
          (local config [default_config])
          (local config_source (str "(defaults)"))
          (local (typed config_key (opt string)) nil)
          (local (typed warned (table [(pair string boolean)])) (table []))
          blank
          (comment "-- The data-folder config wins when it reads; the shipped one is the fallback.")
          (localFunction read_config_file (typed [] (tuple [(opt string) (opt string)])) [
            (for [{_ = null;} {path = null;}] (table [DATA_CONFIG PLUGIN_CONFIG]) ({
              _,
              path,
              ok,
              text,
            }: [
              (local [ok text] [pcall (dot tern "fs.read") path (infix [64 "*" 1024])])
              (if' (infix [ok "and" [type' text] "==" (str "string")]) [
                (return (tuple [(cast text string) path]))
              ])
            ]))
            (return (tuple [nil nil]))
          ])
          blank
          (localFunction load_config (typed [] (table [string])) ({
            text,
            path,
            parsed,
            problems,
          }: [
            (local [text path] [read_config_file])
            (if' (infix [text "==" nil "or" path "==" nil]) [
              (assign config [default_config])
              (assign config_source (str "(defaults)"))
              (assign warned (table []))
              (return (table []))
            ])
            (local [parsed problems] [parse_config text (ifExpr [(infix [path "==" DATA_CONFIG]) (dot tern "plugin.data") (dot tern "plugin.dir")])])
            (assign config parsed)
            (assign config_source path)
            (assign warned (table []))
            (for [{kind = null;} {sound = null;}] (dot config "sounds") ({
              kind,
              sound,
            }: [
              (if' (infix [sound "~=" (str "") "and" (not [(dot tern "fs.exists") sound])]) [
                [(dot table' "insert") problems (infix [kind ".." (str ": file not found: ") ".." sound])]
              ])
            ]))
            (return problems)
          ]))
          blank
          (localFunction snapshot_key (typed [] (opt string)) ({
            text,
            path,
          }: [
            (local [text path] [read_config_file])
            (if' (infix [text "==" nil "or" path "==" nil]) [
              (return nil)
            ])
            (return (infix [path ".." (str "\n") ".." text]))
          ]))
          blank
          (localFunction maybe_reload_config [] ({
            key,
            problems,
          }: [
            (local key [snapshot_key])
            (if' (infix [key "==" config_key]) [
              return
            ])
            (assign config_key key)
            (local problems [load_config])
            (if' (infix [(len problems) ">" 0]) [
              [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." [(dot table' "concat") problems (str "; ")]])]
            ])
          ]))
          blank
          (comment "-- Mute + cross-window claim -----------------------------------------------------------------")
          blank
          (local is_muted false)
          blank
          (localFunction refresh_muted [] ({
            ok,
            value,
          }: [
            (local [ok value] [pcall (dot tern "kv.get") (str "muted")])
            (assign is_muted (infix [ok "and" value "==" true]))
          ]))
          blank
          (comment "-- One chime per moment across windows: whoever claims it plays it.")
          (localFunction claim_chime (typed [] boolean) ({
            now_s,
            ok,
            at,
          }: [
            (local now_s [(dot os "time")])
            (local [ok at] [pcall (dot tern "kv.get") (str "last_chime")])
            (if' (infix [ok "and" [type' at] "==" (str "number") "and" now_s "-" (cast at number) "<" CLAIM_WINDOW_S]) [
              (return false)
            ])
            [pcall (dot tern "kv.set") (str "last_chime") now_s]
            (return true)
          ]))
          blank
          (comment "-- Playback ----------------------------------------------------------------------------------")
          blank
          (localFunction spawn [{argv = table [string];} {path = string;}] ({
            argv,
            path,
            ok,
            err,
          }: [
            (local [ok err] [
              pcall
              (fn [] [
                [
                  (dot tern "process.run")
                  argv
                  (table [(field "timeout_ms" 15000)])
                  (fn [{result = ProcessResult;}] ({result}: [
                    (ifElse (dot result "timed_out") [
                        [(dot tern "log.warn") (infix [(str "Tuturu: playing ") ".." path ".." (str " timed out")])]
                      ] (if' (infix [(dot result "status") "~=" 0]) ({detail}: [
                        (local detail (ifExpr [(infix [(dot result "stderr") "~=" (str "")]) (dot result "stderr") (infix [(str "exit ") ".." [tostring (dot result "status")]])]))
                        [(dot tern "log.warn") (infix [(str "Tuturu: couldn't play ") ".." path ".." (str ": ") ".." [trim detail]])]
                      ])))
                  ]))
                ]
              ])
            ])
            (if' (not ok) [
              [(dot tern "log.warn") (infix [(str "Tuturu: couldn't start the player: ") ".." [tostring err]])]
            ])
          ]))
          blank
          (local (typed linux_player (opt string)) nil)
          (local linux_probe_failed false)
          (local linux_probing false)
          (local (typed linux_queue (table [string])) (table []))
          blank
          (comment "-- Preference order: PipeWire-native first (pw-play ships with pipewire),")
          (comment "-- then PulseAudio, ALSA, then the heavy/general players.")
          (local LINUX_PLAYERS (table [(str "pw-play") (str "paplay") (str "aplay") (str "ffplay") (str "play")]))
          blank
          (localFunction linux_argv (typed [{player = string;} {path = string;}] (table [string])) ({
            player,
            path,
          }: [
            (ifElse (infix [player "==" (str "ffplay")]) [
                (return (table [(str "ffplay") (str "-nodisp") (str "-autoexit") (str "-loglevel") (str "quiet") path]))
              ] (ifElse (infix [player "==" (str "play")]) [
                  (return (table [(str "play") (str "-q") path]))
                ] (ifElse (infix [player "==" (str "aplay")]) [
                    (return (table [(str "aplay") (str "-q") path]))
                  ] (ifElse (infix [player "==" (str "paplay")]) [
                      (return (table [(str "paplay") path]))
                    ] [
                      (return (table [(str "pw-play") path]))
                    ]))))
          ]))
          blank
          (localFunction probe_linux_player [] ({
            names,
            ok,
            err,
          }: [
            (if' (infix [linux_probing "or" linux_probe_failed "or" linux_player "~=" nil]) [
              return
            ])
            (assign linux_probing true)
            (comment "-- One probe per player would serialize N spawns; instead ask sh for the")
            (comment "-- first match in preference order and read back which one answered.")
            (local names [(dot table' "concat") LINUX_PLAYERS (str " ")])
            (local [ok err] [
              pcall
              (fn [] [
                (rows [
                  (dot tern "process.run")
                  (table [(str "sh") (str "-c") (infix [(str "for p in ") ".." names ".." (str "; do command -v $p >/dev/null 2>&1 && { echo $p; exit 0; }; done; exit 1")])])
                  (table [(field "timeout_ms" 5000)])
                  (fn [{result = ProcessResult;}] ({
                    result,
                    name,
                  }: [
                    (assign linux_probing false)
                    (local name [(dot string "match") (dot result "stdout") (str "([%w-]+)")])
                    (ifElse (infix [(dot result "status") "==" 0 "and" name "~=" nil "and" name "~=" (str "")]) [
                        (assign linux_player name)
                        (for [{_ = null;} {path = null;}] linux_queue ({
                          _,
                          path,
                        }: [
                          [spawn [linux_argv name path] path]
                        ]))
                      ] [
                        (assign linux_probe_failed true)
                        [(dot tern "log.warn") (infix [(str "Tuturu: no sound player found (need one of: ") ".." names ".." (str ")")])]
                      ])
                    (assign linux_queue (table []))
                  ]))
                ])
              ])
            ])
            (if' (not ok) [
              (assign linux_probing false)
              (assign linux_probe_failed true)
              (assign linux_queue (table []))
              [(dot tern "log.warn") (infix [(str "Tuturu: couldn't probe for a sound player: ") ".." [tostring err]])]
            ])
          ]))
          blank
          (local warned_no_player false)
          blank
          (localFunction play_file [{path = string;}] ({
            path,
            os_name,
          }: [
            (local os_name (dot tern "runtime.os"))
            (ifElse (infix [os_name "==" (str "ios")]) [
                return
              ] (ifElse (infix [os_name "==" (str "windows")]) [
                  (comment "-- Via wscript (a windowless GUI host): spawning hidden PowerShell")
                  (comment "-- directly still flashes a console box on creation. SoundPlayer")
                  (comment "-- takes WAV only.")
                  [spawn (table [(str "wscript.exe") (str "//Nologo") (infix [(dot tern "plugin.dir") ".." SEP ".." (str "scripts") ".." SEP ".." (str "play.vbs")]) path]) path]
                ] (ifElse (infix [os_name "==" (str "macos")]) [
                    [spawn (table [(str "afplay") path]) path]
                  ] (ifElse (infix [os_name "==" (str "linux")]) ({player}: [
                      (local player linux_player)
                      (ifElse (infix [player "~=" nil]) [
                          [spawn [linux_argv player path] path]
                        ] (ifElse (not linux_probe_failed) [
                            [(dot table' "insert") linux_queue path]
                            [probe_linux_player]
                          ] (if' (not warned_no_player) [
                            (assign warned_no_player true)
                            [(dot tern "log.warn") (str "Tuturu: silent (no Linux player; install pipewire-pulse, alsa-utils, sox or ffmpeg)")]
                          ])))
                    ]) [
                      [(dot tern "log.warn") (infix [(str "Tuturu: no player for ") ".." os_name])]
                    ]))))
          ]))
          blank
          (local last_chime_at (neg (dot math "huge")))
          blank
          (localFunction chime [{kind = string;} {_pane = number;}] ({
            kind,
            _pane,
            path,
            ok_exists,
            exists,
            now,
          }: [
            (local path (idx (dot config "sounds") kind))
            (if' (infix [path "==" nil "or" path "==" (str "") "or" is_muted]) [
              return
            ])
            (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
            (if' (infix [(not ok_exists) "or" (not exists)]) [
              (if' (not (idx warned path)) [
                (assign (idx warned path) true)
                [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." kind ".." (str " sound not found: ") ".." path])]
              ])
              return
            ])
            (local now [(dot tern "now")])
            (if' (infix [now "-" last_chime_at "<" MIN_GAP_MS]) [
              return
            ])
            (if' (not [claim_chime]) [
              return
            ])
            (assign last_chime_at now)
            [play_file path]
          ]))
          blank
          (comment "-- Triggers ----------------------------------------------------------------------------------")
          blank
          (localFunction list_agents (typed [{cx = WindowCx;}] (table [AgentBlock])) ({
            cx,
            ok,
            agents,
          }: [
            (local [ok agents] [
              pcall
              (fn [] [
                (return [(dot cx "agents:list")])
              ])
            ])
            (if' ok [
              (return (cast agents (table [AgentBlock])))
            ])
            (return (table []))
          ]))
          blank
          (local (typed alerts (table [(pair number boolean)])) (table []))
          (local (typed agent_state (table [(pair number string)])) (table []))
          (local seeded false)
          (local tick_count 0)
          blank
          (localFunction tick_body [{cx = WindowCx;}] ({
            cx,
            candidates,
            focused,
            now_alerts,
            now_states,
          }: [
            (update "+=" tick_count 1)
            (if' (infix [tick_count "%" CONFIG_EVERY_TICKS "==" 0]) [
              [maybe_reload_config]
            ])
            [refresh_muted]
            blank
            (comment "-- One candidate per pane; the alert edge wins over a same-tick yield.")
            (local (typed candidates (table [(pair number string)])) (table []))
            (local (typed focused (table [(pair number boolean)])) (table []))
            blank
            (local (typed now_alerts (table [(pair number boolean)])) (table []))
            (for [{_ = null;} {pane = null;}] [(dot cx "session:panes")] ({
              _,
              pane,
              id,
              alerted,
            }: [
              (local id (dot pane "pane"))
              (local alerted (infix [(dot pane "alert") "==" true]))
              (assign (idx now_alerts id) alerted)
              (assign (idx focused id) (infix [(dot pane "focused") "==" true]))
              (if' (infix [seeded "and" alerted "and" (not (idx alerts id))]) [
                (assign (idx candidates id) (str "alert"))
              ])
            ]))
            (assign alerts now_alerts)
            blank
            (local (typed now_states (table [(pair number string)])) (table []))
            (for [{_ = null;} {agent = null;}] [list_agents cx] ({
              _,
              agent,
              id,
              prev,
            }: [
              (local id (dot agent "pane"))
              (assign (idx now_states id) (dot agent "state"))
              (local prev (idx agent_state id))
              (if' (infix [prev "==" (str "working") "and" (infix [(dot agent "state") "==" (str "idle") "or" (dot agent "state") "==" (str "waiting_input")])]) [
                (if' (infix [(idx candidates id) "==" nil]) [
                  (assign (idx candidates id) (ifExpr [(infix [(dot agent "state") "==" (str "waiting_input")]) (str "alert") (str "yield")]))
                ])
              ])
            ]))
            (assign agent_state now_states)
            blank
            (for [{id = null;} {kind = null;}] candidates ({
              id,
              kind,
            }: [
              (ifElse (infix [(dot config "only_unfocused") "and" (idx focused id)]) [
                  (comment "-- You are looking at it; no chime.")
                ] [
                  [chime kind id]
                ])
            ]))
            (assign seeded true)
          ]))
          blank
          (comment "-- The timer re-arms first so one bad tick can't stop the loop.")
          (localFunction tick [{cx = opt WindowCx;}] ({
            cx,
            ok,
            err,
          }: [
            [(dot tern "timer") TICK_MS tick]
            (if' (infix [cx "==" nil]) [
              return
            ])
            (local [ok err] [pcall tick_body (cast cx WindowCx)])
            (if' (not ok) [
              [(dot tern "log.warn") (infix [(str "Chime tick failed: ") ".." [tostring err]])]
            ])
          ]))
          blank
          [(dot tern "timer") TICK_MS tick]
          blank
          [
            (dot tern "on")
            (str "command_finished")
            (fn [{ev = CommandFinishedEvent;} {cx = WindowCx;}] ({
              ev,
              cx,
              ok,
              info,
            }: [
              (if' (infix [(dot ev "took_ms") "<" (dot config "min_seconds") "*" 1000]) [
                return
              ])
              (local [ok info] [
                pcall
                (fn (typed [] (opt PaneInfo)) [
                  (return [(dot cx "session:pane") (dot ev "pane")])
                ])
              ])
              (if' (infix [(not ok) "or" info "==" nil]) [
                return
              ])
              (if' (infix [(dot config "only_unfocused") "and" (dot info "focused")]) [
                return
              ])
              [chime (str "done") (dot ev "pane")]
            ]))
          ]
          blank
          (comment "-- Palette + status ----------------------------------------------------------------------------")
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "mute"))
              (field "title" (str "Tuturu: Mute / unmute"))
              (field "icon" (str "bell"))
              (field "run" (fn [{cx = WindowCx;}] ({cx}: [
                (assign is_muted (not is_muted))
                [pcall (dot tern "kv.set") (str "muted") is_muted]
                [(dot tern "chrome.refresh")]
                [(dot cx ":toast") (str "info") (str "Chime") (ifExpr [is_muted (str "Muted") (str "Unmuted")])]
              ])))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "test"))
              (field "title" (str "Tuturu: Play test sound"))
              (field "icon" (str "bell"))
              (field "run" (fn [{cx = WindowCx;}] ({
                cx,
                path,
                ok_exists,
                exists,
              }: [
                (local path (idx (dot config "sounds") (str "yield")))
                (if' (infix [path "==" nil "or" path "==" (str "")]) [
                  [(dot cx ":toast") (str "error") (str "Chime") (str "No yield sound configured")]
                  return
                ])
                (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
                (if' (infix [(not ok_exists) "or" (not exists)]) [
                  [(dot cx ":toast") (str "error") (str "Chime") (infix [(str "Missing: ") ".." path])]
                  return
                ])
                [play_file path]
                [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Playing ") ".." path])]
              ])))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "reload"))
              (field "title" (str "Tuturu: Reload sounds"))
              (field "icon" (str "bell"))
              (field "run" (fn [{cx = WindowCx;}] ({
                cx,
                problems,
              }: [
                (assign config_key [snapshot_key])
                (local problems [load_config])
                (ifElse (infix [(len problems) "==" 0]) [
                    [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Sounds reloaded from ") ".." config_source])]
                  ] [
                    [(dot cx ":toast") (str "error") (str "Chime") [(dot table' "concat") problems (str "\n")]]
                  ])
              ])))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "diagnose"))
              (field "title" (str "Tuturu: Diagnose panes and agents"))
              (field "icon" (str "bell"))
              (field "run" (fn [{cx = WindowCx;}] ({
                cx,
                lines,
                out,
                ok_write,
                err,
              }: [
                (local (typed lines (table [string])) (table []))
                [(dot table' "insert") lines (infix [(str "config: ") ".." config_source])]
                [(dot table' "insert") lines (infix [(str "muted: ") ".." [tostring is_muted]])]
                [(dot table' "insert") lines (infix [(str "only_unfocused: ") ".." [tostring (dot config "only_unfocused")]])]
                [(dot table' "insert") lines (infix [(str "min_seconds: ") ".." [tostring (dot config "min_seconds")]])]
                (for [{_ = null;} {kind = null;}] (table [(str "alert") (str "yield") (str "done")]) ({
                  _,
                  kind,
                  path,
                  mark,
                }: [
                  (local path (idx (dot config "sounds") kind))
                  (local mark (str "(off)"))
                  (if' (infix [path "~=" nil "and" path "~=" (str "")]) ({
                    ok_exists,
                    exists,
                  }: [
                    (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
                    (assign mark (infix [path ".." (ifExpr [(infix [ok_exists "and" exists]) (str "") (str "  MISSING")])]))
                  ]))
                  [(dot table' "insert") lines (infix [kind ".." (str " = ") ".." mark])]
                ]))
                [(dot table' "insert") lines (str "")]
                [(dot table' "insert") lines (str "panes:")]
                (for [{_ = null;} {pane = null;}] [(dot cx "session:panes")] ({
                  _,
                  pane,
                }: [
                  (rows [(dot table' "insert") lines (rows (infix [(str "  ") ".." [tostring (dot pane "pane")] ".." (str " kind=") ".." [tostring (dot pane "kind")] ".." (str " program=") ".." [tostring (dot pane "program")] ".." (str " busy=") ".." [tostring (dot pane "busy")] ".." (str " alert=") ".." [tostring (dot pane "alert")] ".." (str " focused=") ".." [tostring (dot pane "focused")] ".." (str " at_prompt=") ".." [tostring (dot pane "at_prompt")] ".." (str " title=") ".." [(dot string "sub") (dot pane "title") 1 60]]))])
                ]))
                [(dot table' "insert") lines (str "")]
                [(dot table' "insert") lines (str "agents:")]
                (for [{_ = null;} {agent = null;}] [list_agents cx] ({
                  _,
                  agent,
                }: [
                  (rows [(dot table' "insert") lines (rows (infix [(str "  ") ".." [tostring (dot agent "pane")] ".." (str " state=") ".." (dot agent "state") ".." (str " command=") ".." [tostring (dot agent "command")] ".." (str " model=") ".." [tostring (dot agent "model")]]))])
                ]))
                (local out (infix [(dot tern "plugin.data") ".." SEP ".." (str "diagnose.txt")]))
                (local [ok_write err] [pcall (dot tern "fs.write") out (infix [[(dot table' "concat") lines (str "\n")] ".." (str "\n")])])
                (ifElse ok_write [
                    [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Wrote ") ".." out])]
                  ] [
                    [(dot cx ":toast") (str "error") (str "Chime") (infix [(str "Couldn't write ") ".." out ".." (str ": ") ".." [tostring err]])]
                  ])
              ])))
            ]))
          ]
          blank
          (comment "-- Mute is invisible otherwise; the segment shows it and clicks back to sound.")
          [
            (dot tern "chrome.status")
            (fn (typed [{_pane = StatusPaneInfo;}] (opt (table [StatusSegment]))) ({_pane}: [
              (if' is_muted [
                (return (table [(table [(field "text" (str "tuturu muted")) (field "icon" (str "bell")) (field "tone" (str "muted")) (field "command" (str "plugin.tuturu.mute"))])]))
              ])
              (return nil)
            ]))
          ]
          blank
          (comment "-- Startup -------------------------------------------------------------------------------------")
          blank
          [refresh_muted]
          (assign config_key [snapshot_key])
          (local startup_problems [load_config])
          (if' (infix [(len startup_problems) ">" 0]) [
            [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." [(dot table' "concat") startup_problems (str "; ")]])]
          ])
        ]))
        generators.luau));
      "plugins/ui-menu/plugin.toml" = ./config/plugins/ui-menu/plugin.toml;
      "plugins/ui-menu/rail.luau" = generators.sourceFile "rail.luau" (generators.luau.render (({
          AgentFinishedEvent,
          AgentStateEvent,
          TabInfo,
          any,
          assign,
          blank,
          boolean,
          dot,
          field,
          fn,
          for,
          hex,
          idx,
          if',
          ifElse,
          ifExpr,
          infix,
          ipairs,
          len,
          local,
          localFunction,
          math,
          nil,
          not,
          number,
          opt,
          os,
          pair,
          paren,
          pcall,
          return,
          rows,
          str,
          string,
          table,
          table',
          tern,
          tonumber,
          tostring,
          tuple,
          type',
          typed,
          unicode,
          utf8,
          ...
        }: ({
          on,
          MARKED,
          enabled,
          COLORS,
          SHELLS,
          SECTIONS,
          SECTION_MARK,
          STATUS_MARK,
          AGE_BASE,
          AGE_TICK_MS,
          color_at,
          agent_state,
          unseen,
          since,
          marks,
          age_index,
          id_list,
          toggle,
          save_map,
          load_map,
          focused_tab,
          load,
          prune,
          tab_view,
          arrange,
          tick,
          apply,
          strip_icon,
        }: [
          (local (typed on (table [(pair string boolean)])) (table []))
          blank
          (local MARKED (table [(str "rail_sections") (str "rail_status") (str "rail_ages") (str "rail_compact")]))
          blank
          (localFunction enabled (typed [] boolean) [
            (for [{_ = null;} {id = null;}] [ipairs MARKED] ({
              _,
              id,
            }: [
              (if' (idx on id) [
                (return true)
              ])
            ]))
            (return false)
          ])
          blank
          (local COLORS (table [(str "red") (str "orange") (str "yellow") (str "green") (str "teal") (str "blue") (str "purple") (str "pink")]))
          (local SHELLS (table [(field "zsh" true) (field "bash" true) (field "fish" true) (field "nu" true) (field "sh" true) (field "dash" true) (field "ksh" true)]))
          (local SECTIONS (table [(str "pinned") (str "needs") (str "working") (str "idle")]))
          (local SECTION_MARK (table [(field "pinned" (str [(unicode "2061")])) (field "needs" (str [(unicode "2062")])) (field "working" (str [(unicode "2063")])) (field "idle" (str [(unicode "2064")]))]))
          (local STATUS_MARK (rows (table [
            (field "working" (str ""))
            (field "input" (str [(unicode "206B")]))
            (field "completed" (str [(unicode "206C")]))
            (field "failed" (str [(unicode "206D")]))
            (field "idle" (str [(unicode "206E")]))
          ])))
          (local AGE_BASE (hex 917760))
          (local AGE_TICK_MS 30000)
          blank
          (local color_at 0)
          (local (typed agent_state (table [(pair number string)])) (table []))
          (local (typed unseen (table [(pair number string)])) (table []))
          (local (typed since (table [(pair number number)])) (table []))
          (local (typed marks (table [(pair number string)])) (table []))
          blank
          (localFunction age_index (typed [{seconds = number;}] number) ({
            seconds,
            minutes,
            hours,
          }: [
            (local minutes [(dot math "floor") (infix [seconds "/" 60])])
            (if' (infix [minutes "<" 60]) [
              (return minutes)
            ])
            (local hours [(dot math "floor") (infix [minutes "/" 60])])
            (if' (infix [hours "<" 24]) [
              (return (infix [59 "+" hours]))
            ])
            (return (infix [82 "+" [(dot math "min") [(dot math "floor") (infix [hours "/" 24])] 30]]))
          ]))
          blank
          (localFunction id_list (typed [{key = string;}] (table [number])) ({
            key,
            saved,
            list,
          }: [
            (local saved [(dot tern "kv.get") key])
            (local list (table []))
            (if' (infix [[type' saved] "==" (str "table")]) [
              (for [{_ = null;} {id = null;}] [ipairs saved] ({
                _,
                id,
              }: [
                (if' (infix [[type' id] "==" (str "number")]) [
                  (assign (idx list (infix [(len list) "+" 1])) id)
                ])
              ]))
            ])
            (return list)
          ]))
          blank
          (localFunction toggle (typed [{key = string;} {id = number;}] boolean) ({
            key,
            id,
            kept,
            had,
          }: [
            (local kept (table []))
            (local had false)
            (for [{_ = null;} {other = null;}] [ipairs [id_list key]] ({
              _,
              other,
            }: [
              (ifElse (infix [other "==" id]) [
                  (assign had true)
                ] [
                  (assign (idx kept (infix [(len kept) "+" 1])) other)
                ])
            ]))
            (if' (not had) [
              (assign (idx kept (infix [(len kept) "+" 1])) id)
            ])
            [(dot tern "kv.set") key [(dot tern "json.array") kept]]
            (return (not had))
          ]))
          blank
          (localFunction save_map [{key = string;} {map = table [(pair number any)];}] ({
            key,
            map,
            saved,
          }: [
            (local saved (table []))
            (for [{pane = null;} {value = null;}] map ({
              pane,
              value,
            }: [
              (assign (idx saved [tostring pane]) value)
            ]))
            [(dot tern "kv.set") key saved]
          ]))
          blank
          (localFunction load_map (typed [{key = string;} {kind = string;}] (table [(pair number any)])) ({
            key,
            kind,
            map,
            saved,
          }: [
            (local map (table []))
            (local saved [(dot tern "kv.get") key])
            (if' (infix [[type' saved] "==" (str "table")]) [
              (for [{pane = null;} {value = null;}] saved ({
                pane,
                value,
                id,
              }: [
                (local id [tonumber pane])
                (if' (infix [id "and" [type' value] "==" kind]) [
                  (assign (idx map id) value)
                ])
              ]))
            ])
            (return map)
          ]))
          blank
          (localFunction focused_tab (typed [{cx = null;}] (opt number)) ({
            cx,
            pane,
          }: [
            (local pane [(dot cx "session:focused")])
            (return (infix [pane "and" [(dot cx "session:tab_of") pane] "or" nil]))
          ]))
          blank
          (localFunction load [{cx = null;}] ({
            cx,
            ok,
            list,
          }: [
            (assign unseen [load_map (str "rail_unseen") (str "string")])
            (assign since [load_map (str "rail_since") (str "number")])
            (assign agent_state (table []))
            (local [ok list] [
              pcall
              (fn [] [
                (return [(dot cx "agents:list")])
              ])
            ])
            (if' ok [
              (for [{_ = null;} {agent = null;}] [ipairs list] ({
                _,
                agent,
              }: [
                (assign (idx agent_state (dot agent "pane")) (dot agent "state"))
              ]))
            ])
          ]))
          blank
          (localFunction prune [{cx = null;}] ({
            cx,
            focused,
            live,
            changed,
            tabs,
            pins,
            kept,
          }: [
            (local focused [focused_tab cx])
            (local live (table []))
            (for [{_ = null;} {pane = null;}] [ipairs [(dot cx "session:panes")]] ({
              _,
              pane,
            }: [
              (assign (idx live (dot pane "pane")) (dot pane "tab"))
            ]))
            (local changed false)
            (for [{pane = null;}] unseen ({pane}: [
              (if' (infix [(idx live pane) "==" nil "or" (idx live pane) "==" focused]) [
                (assign (idx unseen pane) nil)
                (assign changed true)
              ])
            ]))
            (if' changed [
              [save_map (str "rail_unseen") unseen]
            ])
            (assign changed false)
            (for [{pane = null;}] since ({pane}: [
              (if' (infix [(idx live pane) "==" nil]) [
                (assign (idx since pane) nil)
                (assign changed true)
              ])
            ]))
            (if' changed [
              [save_map (str "rail_since") since]
            ])
            (local tabs (table []))
            (for [{_ = null;} {tab = null;}] [ipairs [(dot cx "session:tabs")]] ({
              _,
              tab,
            }: [
              (assign (idx tabs (dot tab "id")) true)
            ]))
            (local pins [id_list (str "rail_pins")])
            (local kept (table []))
            (for [{_ = null;} {id = null;}] [ipairs pins] ({
              _,
              id,
            }: [
              (if' (idx tabs id) [
                (assign (idx kept (infix [(len kept) "+" 1])) id)
              ])
            ]))
            (if' (infix [(len kept) "~=" (len pins)]) [
              [(dot tern "kv.set") (str "rail_pins") [(dot tern "json.array") kept]]
            ])
          ]))
          blank
          (localFunction tab_view (typed [{cx = null;} {tab = TabInfo;}] (tuple [string (opt number)])) ({
            cx,
            tab,
            working,
            input,
            completed,
            failed,
            stamp,
            status,
          }: [
            (local [working input completed failed] (tuple [(dot tab "busy") false false false]))
            (local (typed stamp (opt number)) nil)
            (for [{_ = null;} {pane = null;}] [ipairs [(dot cx "session:panes")]] ({
              _,
              pane,
            }: [
              (if' (infix [(dot pane "tab") "==" (dot tab "id")]) ({
                state,
                at,
              }: [
                (local state (idx agent_state (dot pane "pane")))
                (ifElse (infix [state "==" (str "working")]) [
                    (assign working true)
                  ] (if' (infix [state "==" (str "waiting_input")]) [
                    (assign input true)
                  ]))
                (ifElse (infix [(idx unseen (dot pane "pane")) "==" (str "failed")]) [
                    (assign failed true)
                  ] (if' (infix [(idx unseen (dot pane "pane")) "==" (str "done")]) [
                    (assign completed true)
                  ]))
                (local at (idx since (dot pane "pane")))
                (if' (infix [at "and" (infix [(not stamp) "or" at ">" stamp])]) [
                  (assign stamp at)
                ])
              ]))
            ]))
            (local status (rows (ifExpr [[input] [(str "input")] [working (str "working")] [failed (str "failed")] [completed (str "completed")] [(str "idle")]])))
            (return (tuple [status stamp]))
          ]))
          blank
          (localFunction arrange [{cx = null;}] ({
            cx,
            pins,
            rank,
            now,
            sessions,
          }: [
            [prune cx]
            (local pins (table []))
            (for [{_ = null;} {id = null;}] [ipairs [id_list (str "rail_pins")]] ({
              _,
              id,
            }: [
              (assign (idx pins id) true)
            ]))
            (local rank (table []))
            (for [{i = null;} {name = null;}] [ipairs SECTIONS] ({
              i,
              name,
            }: [
              (assign (idx rank name) i)
            ]))
            (local now [(dot os "time")])
            (local (typed sessions (table [(pair number (table [(table [(field "tab" TabInfo) (field "section" string)])]))])) (table []))
            (assign marks (table []))
            (for [{_ = null;} {tab = null;}] [ipairs [(dot cx "session:tabs")]] ({
              _,
              tab,
              status,
              stamp,
              section,
              age,
              list,
            }: [
              (local [status stamp] [tab_view cx tab])
              (local section (rows (ifExpr [[(not (dot on "rail_sections"))] [(str "idle")] [(idx pins (dot tab "id"))] [(str "pinned")] [(infix [status "==" (str "input")]) (str "needs")] [(infix [status "==" (str "working")]) (str "working")] [(str "idle")]])))
              (local age (ifExpr [stamp [(dot utf8 "char") (infix [AGE_BASE "+" [age_index [(dot math "max") 0 (infix [now "-" stamp])]]])] (str "")]))
              (assign (idx marks (dot tab "id")) (infix [(idx SECTION_MARK section) ".." (idx STATUS_MARK (ifExpr [(dot on "rail_status") status (str "idle")])) ".." age]))
              (local list (infix [(idx sessions (dot tab "session")) "or" (table [])]))
              (assign (idx sessions (dot tab "session")) list)
              (assign (idx list (infix [(len list) "+" 1])) (table [(field "tab" tab) (field "section" section)]))
            ]))
            (for [{_ = null;} {list = null;}] sessions ({
              _,
              list,
            }: [
              [
                (dot table' "sort")
                list
                (fn [{a = null;} {b = null;}] ({
                  a,
                  b,
                }: [
                  (if' (infix [(dot a "section") "~=" (dot b "section")]) [
                    (return (infix [(idx rank (dot a "section")) "<" (idx rank (dot b "section"))]))
                  ])
                  (return (infix [(dot a "tab.position") "<" (dot b "tab.position")]))
                ]))
              ]
              (if' (dot on "rail_sections") [
                (for [{position = null;} {entry = null;}] [ipairs list] ({
                  position,
                  entry,
                }: [
                  (if' (infix [(dot entry "tab.position") "~=" position]) [
                    [(dot cx "layout:order_tab") (dot entry "tab.id") position]
                  ])
                ]))
              ])
            ]))
            [(dot tern "chrome.refresh")]
          ]))
          blank
          (localFunction tick [{cx = null;}] ({cx}: [
            (if' (infix [cx "and" [enabled]]) [
              [arrange cx]
            ])
            [(dot tern "timer") AGE_TICK_MS tick]
          ]))
          blank
          (localFunction apply [{cx = null;}] ({cx}: [
            (ifElse [enabled] [
                [load cx]
                [arrange cx]
              ] [
                (assign marks (table []))
                [(dot tern "chrome.refresh")]
              ])
          ]))
          blank
          [
            (dot tern "on")
            (str "window_start")
            (fn [{cx = null;}] ({cx}: [
              [apply cx]
            ]))
          ]
          blank
          [
            (dot tern "timer")
            0
            (fn [{cx = null;}] ({cx}: [
              (if' (infix [cx "and" [enabled]]) [
                [load cx]
              ])
              [tick cx]
            ]))
          ]
          blank
          (for [{_ = null;} {name = null;}] [ipairs (table [(str "tab_created") (str "tab_closed") (str "pane_closed") (str "command_started") (str "command_finished") (str "focus")])] ({
            _,
            name,
          }: [
            [
              (dot tern "on")
              name
              (fn [{_ = null;} {cx = null;}] ({
                _,
                cx,
              }: [
                (if' [enabled] [
                  [arrange cx]
                ])
              ]))
            ]
          ]))
          blank
          [
            (dot tern "on")
            (str "agent_state")
            (fn [{ev = AgentStateEvent;} {cx = null;}] ({
              ev,
              cx,
            }: [
              (if' (not [enabled]) [
                return
              ])
              (assign (idx agent_state (dot ev "pane")) (dot ev "new"))
              (if' (infix [(dot ev "old") "~=" (dot ev "new")]) [
                (assign (idx since (dot ev "pane")) [(dot os "time")])
                [save_map (str "rail_since") since]
              ])
              (if' (infix [(dot ev "new") "==" (str "working") "and" (idx unseen (dot ev "pane"))]) [
                (assign (idx unseen (dot ev "pane")) nil)
                [save_map (str "rail_unseen") unseen]
              ])
              [arrange cx]
            ]))
          ]
          blank
          [
            (dot tern "on")
            (str "agent_finished")
            (fn [{ev = AgentFinishedEvent;} {cx = null;}] ({
              ev,
              cx,
            }: [
              (if' (not [enabled]) [
                return
              ])
              (ifElse (infix [(dot ev "result") "==" (str "closed") "or" (dot ev "result") "==" (str "exited")]) [
                  (assign (idx unseen (dot ev "pane")) nil)
                  (assign (idx agent_state (dot ev "pane")) nil)
                ] (if' (infix [[(dot cx "session:tab_of") (dot ev "pane")] "~=" [focused_tab cx]]) [
                  (assign (idx unseen (dot ev "pane")) (dot ev "result"))
                ]))
              (assign (idx since (dot ev "pane")) [(dot os "time")])
              [save_map (str "rail_since") since]
              [save_map (str "rail_unseen") unseen]
              [arrange cx]
            ]))
          ]
          blank
          (localFunction strip_icon (typed [{title = string;}] string) ({
            title,
            ok,
            first,
          }: [
            (local [ok first] [pcall (dot utf8 "codepoint") title 1])
            (if' (infix [ok "and" first "and" (infix [(paren (infix [first ">=" (hex 57344) "and" first "<=" (hex 63743)])) "or" first ">=" (hex 983040)])]) ({rest}: [
              (local rest (infix [[(dot utf8 "offset") title 2] "or" (len title) "+" 1]))
              (return (paren [(dot [(dot title ":sub") rest] ":gsub") (str "^%s+") (str "")]))
            ]))
            (return title)
          ]))
          blank
          [
            (dot tern "chrome.tab_title")
            (fn [{tab = null;}] ({
              tab,
              title,
            }: [
              (if' (not [enabled]) [
                (return nil)
              ])
              (local title (dot tab "name"))
              (if' (infix [(not title) "or" title "==" (str "")]) [
                (assign title [strip_icon (infix [(dot tab "title") "or" (str "")])])
                (if' (idx SHELLS (dot tab "program")) [
                  (assign title [(dot title ":gsub") (str "^[^%s:]+@[^%s:]+:%s*") (str "")])
                ])
                (if' (infix [title "==" (str "")]) ({cwd}: [
                  (local cwd (infix [(dot tab "cwd") "or" (str "")]))
                  (assign title (infix [[(dot cwd ":match") (str "([^/]+)/*$")] "or" cwd]))
                ]))
              ])
              (return (infix [(infix [(idx marks (dot tab "id")) "or" (str "")]) ".." title]))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "pin"))
              (field "title" (str "Sidebar: Pin or unpin this tab"))
              (field "icon" (str "pin"))
              (field "run" (fn [{cx = null;}] ({
                cx,
                tab,
              }: [
                (local tab [focused_tab cx])
                (if' (infix [tab "and" (dot on "rail_sections")]) [
                  [(dot cx ":toast") (str "info") (infix [[toggle (str "rail_pins") tab] "and" (str "Pinned") "or" (str "Unpinned")])]
                  [arrange cx]
                ])
              ])))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "colour"))
              (field "title" (str "Sidebar: Colour this tab"))
              (field "icon" (str "palette"))
              (field "run" (fn [{cx = null;}] ({
                cx,
                tab,
              }: [
                (local tab [focused_tab cx])
                (if' tab [
                  (assign color_at (infix [color_at "%" (len COLORS) "+" 1]))
                  [(dot cx "layout:color_tab") tab (idx COLORS color_at)]
                ])
              ])))
            ]))
          ]
          blank
          [
            (dot tern "command")
            (rows (table [
              (field "id" (str "autohide"))
              (field "title" (str "Sidebar: Toggle auto-hide"))
              (field "icon" (str "sidebar"))
              (field "run" (fn [{cx = null;}] ({
                cx,
                hidden,
              }: [
                (local hidden (not [(dot cx "settings:get") (str "tabs_autohide")]))
                [(dot cx "settings:set") (str "tabs_autohide") hidden]
                [(dot cx ":toast") (str "info") (infix [hidden "and" (str "Sidebar tucks away") "or" (str "Sidebar stays open")])]
              ])))
            ]))
          ]
          blank
          [(dot tern "bind") (str "ctrl+alt+p") (str "plugin.ui-menu.pin")]
          [(dot tern "bind") (str "ctrl+alt+j") (str "next_tab")]
          [(dot tern "bind") (str "ctrl+alt+k") (str "previous_tab")]
          blank
          (return (rows (table [
            (field "tweaks" (rows (table [
              (rows (table [
                (field "id" (str "rail_sections"))
                (field "label" (str "sections: pinned, needs you, working, idle"))
                (field "group" (str "Rail"))
                (field "apply" apply)
              ]))
              (rows (table [
                (field "id" (str "rail_status"))
                (field "label" (str "status rings and lines"))
                (field "group" (str "Rail"))
                (field "apply" apply)
              ]))
              (rows (table [
                (field "id" (str "rail_ages"))
                (field "label" (str "ages"))
                (field "group" (str "Rail"))
                (field "apply" apply)
              ]))
              (rows (table [
                (field "id" (str "rail_compact"))
                (field "label" (str "one-line idle rows"))
                (field "group" (str "Rail"))
                (field "apply" apply)
              ]))
              (rows (table [
                (field "id" (str "rail_card"))
                (field "label" (str "selected tab card"))
                (field "group" (str "Rail"))
              ]))
              (rows (table [
                (field "id" (str "rail_header"))
                (field "label" (str "+ and bell in the header"))
                (field "group" (str "Rail"))
              ]))
            ])))
            (field "bind" (fn [{state = table [(pair string boolean)];}] ({state}: [
              (assign on state)
            ])))
          ])))
        ]))
        generators.luau));
      "plugins/ui-menu/snippets/rail.css" = "${flakeInputs.tern-ozette}/rail.css";
      "plugins/ui-menu/snippets/settings.css" = "${flakeInputs.tern-ozette}/settings.css";
      "plugins/ui-menu/snippets/bubbles.css" = "${flakeInputs.tern-ozette}/bubbles.css";
      "plugins/ui-menu/snippets/account.css" = generators.sourceFile "account.css" (generators.cssSource [
        {
          select = ".tn-peers";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/answer-bubbles.css" = generators.sourceFile "answer-bubbles.css" (generators.cssSource [
        {
          select = ".sf-chat-reader.sf-main > [data-role='omp.assistant'] > .sf-md, .sf-chat-reader.sf-main > [data-role='omp.chat.msg'] > [data-role='omp.assistant'] > .sf-md";
          set = [
            ["align-self" "flex-start"]
            ["max-width" "var(--omp-reply-max, 82%)"]
            ["padding" "var(--omp-reply-pad, 10px 16px)"]
            ["border-radius" "var(--omp-reply-radius, 18px 18px 18px 6px)"]
            ["background" "var(--omp-reply-bg, var(--l1))"]
            ["box-shadow" "var(--omp-reply-edge, 0 0 0 1px var(--l1), 0 10px 26px -16px light-dark(rgba(0, 0, 0, 0.24), rgba(0, 0, 0, 0.65)), inset 0 1px 0 var(--glass-hi))"]
          ];
        }
        {
          select = ".sf-chat-reader.sf-main > [data-role='omp.assistant'] > .sf-md .md > :last-child, .sf-chat-reader.sf-main > [data-role='omp.chat.msg'] > [data-role='omp.assistant'] > .sf-md .md > :last-child";
          set = [
            ["margin-bottom" "0"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/answer-frost.css" = generators.sourceFile "answer-frost.css" (generators.cssSource [
        {
          select = ":root:not(#s0):not(#s1) .sf-chat-reader.sf-main > [data-role='omp.assistant'] > .sf-md, :root:not(#s0):not(#s1) .sf-chat-reader.sf-main > [data-role='omp.chat.msg'] > [data-role='omp.assistant'] > .sf-md";
          set = [
            ["background" "var(--omp-reply-bg, var(--frost-reply-fill, var(--frost-fill)))"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
            ["box-shadow" "var(--omp-reply-edge, var(--frost-edge))"]
            ["--t1" "var(--frost-reply-ink, var(--frost-ink))"]
            ["color" "var(--frost-reply-ink, var(--frost-ink))"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/attention.css" = generators.sourceFile "attention.css" (generators.cssSource [
        {
          select = ":is(.tn-dk-c, .tn-face)[data-st=\"bell\"]";
          set = [
            ["--st" "light-dark(#7c3aed, #c4a7ff)"]
          ];
        }
        {
          select = ":is(.tn-dk-c, .tn-face)[data-st=\"waiting\"]";
          set = [
            ["--st" "light-dark(#c2410c, #ff7a4d)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-answer-bubbles.css" = generators.sourceFile "bot-answer-bubbles.css" (generators.cssSource [
        {
          select = ":root:not(#ob) [data-role='omp.bot.reply'] > :is([data-role='omp.assistant'], [data-role='omp.assistant.rewound'])";
          set = [
            ["align-self" "flex-start"]
            ["max-width" "var(--omp-reply-max, min(80%, 560px))"]
            ["margin" "0"]
            ["padding" "var(--omp-reply-pad, 7px 12px)"]
            ["border-radius" "var(--omp-reply-radius, var(--r-card))"]
            ["background" "var(--omp-reply-bg, rgb(from var(--t1) r g b / 6%))"]
            ["box-shadow" "var(--omp-reply-edge, none)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-answer-frost.css" = generators.sourceFile "bot-answer-frost.css" (generators.cssSource [
        {
          select = ":root:not(#s0):not(#s1) [data-role='omp.bot.reply'] > :is([data-role='omp.assistant'], [data-role='omp.assistant.rewound'])";
          set = [
            ["background" "var(--omp-reply-bg, var(--frost-reply-fill, var(--frost-fill)))"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
            ["box-shadow" "var(--omp-reply-edge, var(--frost-edge))"]
            ["--t1" "var(--frost-reply-ink, var(--frost-ink))"]
            ["color" "var(--frost-reply-ink, var(--frost-ink))"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-ask.css" = generators.sourceFile "bot-ask.css" (generators.cssSource [
        {
          select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.editor.ask']";
          set = [
            ["width" "min(100%, 720px)"]
            ["margin" "8px auto"]
            ["padding" "16px"]
            ["border-radius" "var(--r-card)"]
          ];
        }
        {
          select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.ask.question']";
          set = [
            ["font-weight" "600"]
          ];
        }
        {
          select = ":root:not(#ob) [data-role='omp.bot.dock'] [data-role='omp.ask.options']";
          set = [
            ["margin-top" "8px"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-dock.css" = generators.sourceFile "bot-dock.css" (generators.cssSource [
        {
          select = ":root:not(#ob) [data-role='omp.bot.dock'] :is([data-role='omp.composer.context'], [data-role='omp.composer.usage'], [data-role='omp.composer.extras'])";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-events.css" = generators.sourceFile "bot-events.css" (generators.cssSource [
        {
          select = "[data-role='omp.bot.event.row']";
          set = [
            ["align-self" "center"]
            ["max-width" "100%"]
            ["min-height" "24px"]
            ["margin-top" "2px"]
            ["padding" "2px 6px"]
            ["color" "var(--t3)"]
            ["font-size" "12px"]
            ["cursor" "pointer"]
          ];
        }
        {
          select = "[data-role='omp.bot.event.row']:hover";
          set = [
            ["color" "var(--t2)"]
          ];
        }
        {
          select = "[data-role='omp.bot.event.action'], [data-role='omp.bot.event.more']";
          set = [
            ["flex" "none"]
            ["color" "var(--t3)"]
          ];
        }
        {
          select = "[data-role='omp.bot.event.name']";
          set = [
            ["max-width" "min(60vw, 360px)"]
            ["color" "var(--t2)"]
            ["font-weight" "500"]
          ];
        }
        {
          select = "[data-role='omp.bot.event.avatar']";
          set = [
            ["--p" "1px"]
            ["flex" "none"]
            ["width" "32px"]
            ["height" "26px"]
            ["overflow" "hidden"]
            ["align-items" "center"]
            ["justify-content" "center"]
            ["pointer-events" "none"]
          ];
        }
        {
          select = ":is([data-role='omp.bot.event.avatar']) *";
          set = [
            ["pointer-events" "none"]
          ];
        }
        {
          select = ":is([data-role='omp.bot.event.avatar']) :is([data-role='omp.bot.emote'], [data-role='omp.bot.chao.idle'] > [data-role='omp.bot.line']:empty)";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = ":is([data-role='omp.bot.event.avatar']) :is([data-role^='omp.bot.glyph.'], [data-role='omp.bot.blink'] [data-role^='omp.bot.px.'], [data-role^='omp.bot.chao.'])";
          set = [
            ["animation" "none !important"]
          ];
        }
        {
          select = "[data-role='omp.bot.event.detail']";
          set = [
            ["align-self" "center"]
            ["width" "min(100%, 720px)"]
            ["margin" "4px auto 10px"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-jobs.css" = generators.sourceFile "bot-jobs.css" (generators.cssSource [
        {
          select = "[data-role='omp.bot.notice']";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-layout.css" = generators.sourceFile "bot-layout.css" (generators.cssSource [
        {
          select = "[data-role^='omp.bot.chat.']";
          set = [
            ["padding" "2px 4px 10px 6px"]
          ];
        }
        {
          select = "[data-role^='omp.bot.hero.']";
          set = [
            ["--p" "5px"]
            ["padding" "48px 0 20px 0"]
          ];
        }
        {
          select = "[data-role^='omp.bot.top.']";
          set = [
            ["--p" "1px"]
            ["padding" "2px 4px 10px 2px"]
            ["box-shadow" "0 1px 0 var(--l1)"]
          ];
        }
        {
          select = "[data-role='omp.bot.floor']";
          set = [
            ["height" "34vh"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'].sf-void";
          set = [
            ["display" "flex !important"]
          ];
        }
        {
          select = "[data-role='omp.bot.none'], [data-role='omp.bot.none'].sf-void, [data-role='omp.bot.more'], [data-role='omp.bot.more'].sf-void";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-names.css" = generators.sourceFile "bot-names.css" (generators.cssSource [
        {
          select = "[data-role='omp.bot.words']";
          set = [
            ["min-width" "0"]
          ];
        }
        {
          select = "[data-role='omp.bot.name']";
          set = [
            ["font-weight" "600"]
          ];
        }
        {
          select = "[data-role='omp.bot.say']";
          set = [
            ["position" "relative"]
            ["opacity" "0.58"]
          ];
        }
        {
          select = "[data-role^='omp.bot.top.'] [data-role='omp.bot.name']";
          set = [
            ["margin-left" "2px"]
          ];
        }
        {
          select = "[data-role='omp.bot.hello']";
          set = [
            ["margin-top" "14px"]
            ["font-size" "1.5em"]
            ["line-height" "1.3"]
            ["font-weight" "600"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-rail.css" = generators.sourceFile "bot-rail.css" (generators.cssSource [
        {
          select = "#tabbar .tt[data-tc='red']";
          set = [
            ["--bot" "#ff4d5e"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='orange']";
          set = [
            ["--bot" "#ff8a3d"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='yellow']";
          set = [
            ["--bot" "#f2b705"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='green']";
          set = [
            ["--bot" "#2fbf71"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='teal']";
          set = [
            ["--bot" "#19b8c4"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='blue']";
          set = [
            ["--bot" "#3d7bff"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='purple']";
          set = [
            ["--bot" "#8f6bff"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc='pink']";
          set = [
            ["--bot" "#ff5fa8"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc]";
          set = [
            ["border" "none"]
            ["box-shadow" "none"]
            ["border-radius" "10px"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc].on";
          set = [
            ["background" "light-dark(#ececee, #2a2a2d) !important"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .mk.keys, #tabbar .tt[data-tc] .kbd, #tabbar .tt[data-tc] .tn-tc";
          set = [
            ["display" "none"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .nm";
          set = [
            ["color" "light-dark(#18181b, #f2f2f3)"]
            ["font-weight" "500"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .sub";
          set = [
            ["opacity" "0.55"]
            ["font-size" "11px"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .sub::after";
          set = [
            ["font-family" "var(--sans)"]
            ["font-size" "11.5px"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c";
          set = [
            ["position" "relative"]
            ["width" "18px"]
            ["height" "18px"]
            ["color" "transparent"]
            ["background" "none"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c *";
          set = [
            ["opacity" "0"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c::after";
          set = [
            ["content" "''"]
            ["position" "absolute"]
            ["left" "-30px"]
            ["top" "-30px"]
            ["width" "1px"]
            ["height" "1px"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='waiting']::before, #tabbar .tt[data-tc] .tn-dk-c[data-st='failed']::before";
          set = [
            ["content" "''"]
            ["position" "absolute"]
            ["z-index" "1"]
            ["right" "-4px"]
            ["top" "-6px"]
            ["width" "4px"]
            ["height" "4px"]
            ["background" "#f0a020"]
            ["box-shadow" "0 0 0 1px #000"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='working']";
          set = [
            ["animation" "railChaoBob 0.8s steps(1) infinite"]
          ];
        }
        {
          select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='failed']::before";
          set = [
            ["background" "#e5484d"]
          ];
        }
        {
          at = "@keyframes railChaoBob";
          rules = [
            {
              select = "0%, 100%";
              set = [
                ["transform" "translateY(0)"]
              ];
            }
            {
              select = "50%";
              set = [
                ["transform" "translateY(-1px)"]
              ];
            }
          ];
        }
        {
          at = "@media (prefers-reduced-motion: reduce)";
          rules = [
            {
              select = "#tabbar .tt[data-tc] .tn-dk-c[data-st='working']";
              set = [
                ["animation" "none"]
              ];
            }
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-spacing.css" = generators.sourceFile "bot-spacing.css" (generators.cssSource [
        {
          select = ":root:not(#ob) [data-role='omp.bot.reply'], :root:not(#ob) [data-role='omp.bot.you'], :root:not(#ob) [data-role^='omp.bot.eventbox.']";
          set = [
            ["margin" "-4px 0"]
          ];
        }
        {
          select = ":root:not(#ob) [data-role='omp.bot.more'] + [data-role='omp.bot.reply']";
          set = [
            ["margin-top" "-12px"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-stop.css" = generators.sourceFile "bot-stop.css" (generators.cssSource [
        {
          select = "[data-role='omp.bot.stop']";
          set = [
            ["margin-left" "auto"]
            ["padding" "2px 8px"]
            ["border-radius" "9px"]
            ["font-size" "0.85em"]
            ["box-shadow" "0 0 0 1px var(--l2)"]
            ["opacity" "0.75"]
            ["cursor" "pointer"]
          ];
        }
        {
          select = "[data-role='omp.bot.stop']:hover";
          set = [
            ["opacity" "1"]
            ["background" "var(--l1)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-text.css" = generators.sourceFile "bot-text.css" (generators.cssSource [
        {
          select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md";
          set = [
            ["line-height" "1.45"]
          ];
        }
        {
          select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md > :first-child";
          set = [
            ["margin-top" "0"]
          ];
        }
        {
          select = ":root:not(#ob) :is([data-role='omp.bot.reply'], [data-role='omp.bot.you']) .md > :last-child";
          set = [
            ["margin-bottom" "0"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-time.css" = generators.sourceFile "bot-time.css" (generators.cssSource [
        {
          select = "[data-role^='omp.bot.time.']";
          set = [
            ["align-self" "stretch"]
            ["margin" "-2px 0 -8px"]
            ["text-align" "center"]
            ["font-size" "12px"]
            ["line-height" "16px"]
            ["color" "var(--t2)"]
            ["font-family" "var(--sans)"]
          ];
        }
        {
          select = "[data-role='omp.bot.took']";
          set = [
            ["opacity" "0.45"]
            ["font-size" "0.85em"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-tints.css" = generators.sourceFile "bot-tints.css" (generators.cssSource [
        {
          select = "[data-role^='omp.bot.chat.'], [data-role^='omp.bot.hero.'], [data-role^='omp.bot.top.'], [data-role^='omp.bot.eventbox.']";
          set = [
            ["--t" "#8f6bff"]
            ["--p" "2px"]
            ["position" "relative"]
            ["font-family" "var(--sans)"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.red']";
          set = [
            ["--t" "#ff4d5e"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.orange']";
          set = [
            ["--t" "#ff8a3d"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.yellow']";
          set = [
            ["--t" "#f2b705"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.green']";
          set = [
            ["--t" "#2fbf71"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.teal']";
          set = [
            ["--t" "#19b8c4"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.blue']";
          set = [
            ["--t" "#3d7bff"]
          ];
        }
        {
          select = "[data-role^='omp.bot.'][data-role$='.pink']";
          set = [
            ["--t" "#ff5fa8"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-turn-stats.css" = generators.sourceFile "bot-turn-stats.css" (generators.cssSource [
        {
          select = ":root:not(#b0) [data-role='omp.bot.took']";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-yorha-labels.css" = generators.sourceFile "bot-yorha-labels.css" (generators.cssSource [
        {
          select = ":root:not(#oz) [data-role^='omp.bot.time.']";
          set = [
            ["font" "400 11px/1 var(--sans)"]
            ["letter-spacing" "1.5px"]
            ["text-transform" "uppercase"]
            ["color" "var(--t3)"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role^='omp.bot.top.']";
          set = [
            ["box-shadow" "0 1px 0 var(--l3)"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role^='omp.bot.top.'] [data-role='omp.bot.name']";
          set = [
            ["font" "400 16.5px/24px var(--sans)"]
            ["letter-spacing" "2.5px"]
            ["text-transform" "uppercase"]
            ["color" "var(--ink)"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role='omp.bot.event.row']";
          set = [
            ["font" "400 11px/16px var(--sans)"]
            ["letter-spacing" "1.5px"]
            ["text-transform" "uppercase"]
            ["color" "var(--t3)"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role='omp.bot.event.name']";
          set = [
            ["font" "inherit"]
            ["color" "var(--ink)"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role='omp.bot.hello']";
          set = [
            ["font" "400 22px/30px var(--sans)"]
            ["letter-spacing" "2.5px"]
            ["text-transform" "uppercase"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role='omp.bot.say']";
          set = [
            ["font" "400 11px/16px var(--sans)"]
            ["letter-spacing" "0"]
            ["color" "var(--t2)"]
            ["opacity" "1"]
          ];
        }
        {
          select = ":root:not(#oz) [data-role='omp.bot.say']::after";
          set = [
            ["content" "\"\""]
            ["display" "inline-block"]
            ["width" "7px"]
            ["height" "12px"]
            ["margin-left" "6px"]
            ["vertical-align" "-2px"]
            ["background" "var(--ink)"]
            ["animation" "yh-blink calc(1000ms * var(--yh-t)) steps(1, end) 4"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-you-frost.css" = generators.sourceFile "bot-you-frost.css" (generators.cssSource [
        {
          select = ":root:not(#s0):not(#s1) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body > .sf-md";
          set = [
            ["background" "var(--frost-you-fill, var(--frost-fill))"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
            ["box-shadow" "var(--frost-edge)"]
            ["--t1" "var(--frost-you-ink, var(--frost-ink))"]
            ["color" "var(--frost-you-ink, var(--frost-ink))"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bot-you.css" = generators.sourceFile "bot-you.css" (generators.cssSource [
        {
          select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user']";
          set = [
            ["align-self" "flex-end"]
            ["width" "auto"]
            ["max-width" "var(--omp-user-max, min(80%, 560px))"]
            ["margin" "16px 0 0 auto"]
          ];
        }
        {
          select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body";
          set = [
            ["align-self" "flex-end"]
            ["align-items" "flex-start"]
            ["width" "auto"]
            ["max-width" "100%"]
            ["margin" "0"]
            ["padding" "var(--omp-user-pad, 7px 12px)"]
            ["border" "0"]
            ["border-radius" "var(--omp-user-radius, var(--r-card))"]
            ["background" "var(--omp-user-bg, var(--l2))"]
            ["color" "var(--omp-user-ink, currentColor)"]
            ["box-shadow" "var(--omp-user-edge, none)"]
          ];
        }
        {
          select = ":root:not(#ob) [data-role='omp.bot.you'] .sf-card[data-role^='omp.user'] > .sf-card-body > .sf-md";
          set = [
            ["width" "auto"]
            ["max-width" "100%"]
            ["padding" "0"]
            ["border" "0"]
            ["border-radius" "0"]
            ["background" "none"]
            ["color" "inherit"]
            ["box-shadow" "none"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/bottom.css" = generators.sourceFile "bottom.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tn-peers";
          set = [
            ["order" "1 !important"]
            ["margin-top" "0 !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar";
          set = [
            ["overflow-y" "auto !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar > .tb-in";
          set = [
            ["flex" "none !important"]
            ["min-height" "100% !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tb-tabs";
          set = [
            ["flex" "none !important"]
            ["margin" "0 !important"]
            ["overflow" "visible !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar > .tb-in > .tb-add";
          set = [
            ["margin-top" "auto !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/buttons.css" = generators.sourceFile "buttons.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-row";
          set = [
            ["height" "28px !important"]
            ["margin" "2px 6px 0 !important"]
            ["padding" "0 10px !important"]
            ["border-radius" "9px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-add";
          set = [
            ["margin" "4px 6px 0 !important"]
            ["border-radius" "9px !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/centering.css" = generators.sourceFile "centering.css" (generators.cssSource [
        {
          select = "html.tn-themed.lay-rail.tabs-h #tabbar > .tb-in > .tb-tabs";
          set = [
            ["margin-top" "auto !important"]
            ["margin-bottom" "auto !important"]
          ];
        }
        {
          select = "html.tn-themed.lay-rail.tabs-h #tabbar > .tb-in > .tb-add";
          set = [
            ["margin-top" "0 !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/chat-still.css" = generators.sourceFile "chat-still.css" (generators.cssSource [
        {
          select = ":root:not(#s0) [data-role='omp.chat.msg'] .md.streaming";
          set = [
            ["display" "none"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/dividers.css" = generators.sourceFile "dividers.css" (generators.cssSource [
        {
          select = ".tn-div.row, .tn-div.col";
          set = [
            ["background" "transparent"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/files.css" = generators.sourceFile "files.css" (generators.cssSource [
        {
          select = "html.tn-themed .tb-files";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/frost.css" = generators.sourceFile "frost.css" (generators.cssSource [
        {
          select = "html.tn-themed";
          set = [
            ["--frost" "blur(72px) saturate(160%)"]
            ["--frost-fill" "color-mix(in srgb, var(--pop-bg) 28%, transparent)"]
            ["--frost-edge" "0 0 0 1px light-dark(var(--l2), var(--l3)), inset 0 1px 0 var(--glass-hi)"]
            ["--frost-ink" "var(--t1)"]
          ];
        }
        {
          select = "html.tn-themed:not(#s0):not(#s1) :is(.cmdk, .dlg-card, .mdl, .pk-sheet, .sf-overlay.modal > .sf-ov-card, .sf-prefs .pf-editor > .sf-col, .tn-hd, .tn-sc)";
          set = [
            ["background" "var(--frost-fill)"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
          ];
        }
        {
          at = "@media (prefers-contrast: more)";
          rules = [
            {
              select = "html.tn-themed:not(#s0):not(#s1)";
              set = [
                ["--frost" "none"]
                ["--frost-fill" "var(--modal-bg)"]
                ["--frost-you-fill" "initial"]
                ["--frost-you-ink" "initial"]
                ["--frost-reply-fill" "initial"]
                ["--frost-reply-ink" "initial"]
              ];
            }
          ];
        }
      ]);
      "plugins/ui-menu/snippets/grips.css" = generators.sourceFile "grips.css" (generators.cssSource [
        {
          select = "div.csd-ctl, button.tn-grip";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/inbox.css" = generators.sourceFile "inbox.css" (generators.cssSource [
        {
          select = "html.tn-themed #inbox";
          set = [
            ["left" "50% !important"]
            ["top" "50% !important"]
            ["translate" "-50% -50% !important"]
            ["transform-origin" "50% 50% !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/mini.css" = "${flakeInputs.tern-ozette}/mini.css";
      "plugins/ui-menu/snippets/ozette-answer-bubbles.css" = "${flakeInputs.tern-ozette}/ozette-answer-bubbles.css";
      "plugins/ui-menu/snippets/ozette-bot-you.css" = "${flakeInputs.tern-ozette}/ozette-bot-you.css";
      "plugins/ui-menu/snippets/ozette-cmus.css" = "${flakeInputs.tern-ozette}/cmus.css";
      "plugins/ui-menu/snippets/ozette-motion.css" = "${flakeInputs.tern-ozette}/motion.css";
      "plugins/ui-menu/snippets/ozette.css" = "${flakeInputs.tern-ozette}/ozette.css";
      "plugins/ui-menu/snippets/pane-borders.css" = generators.sourceFile "pane-borders.css" (generators.cssSource [
        {
          select = "section.tn-pane";
          set = [
            ["border" "1px solid var(--l2, rgba(127, 127, 127, 0.2))"]
            ["transition" "border-color 220ms cubic-bezier(0.22, 0.61, 0.36, 1), box-shadow 220ms cubic-bezier(0.22, 0.61, 0.36, 1)"]
          ];
        }
        {
          select = "section.tn-pane.on";
          set = [
            ["border-color" "var(--accent-ink, rgba(98, 168, 255, 0.85))"]
            ["box-shadow" "0 0 0 1px rgba(98, 168, 255, 0.25)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_ages.css" = generators.sourceFile "rail_ages.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt .mk .hint";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt .mk";
          set = [
            ["flex" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt .mk::before";
          set = [
            ["font-size" "11px"]
            ["color" "var(--t4)"]
            ["font-family" "var(--sans)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0100\"] .sub::before";
          set = [
            ["content" "\"Working · now\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0100\"] .mk::before";
          set = [
            ["content" "\"now\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0101\"] .sub::before";
          set = [
            ["content" "\"Working · 1m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0101\"] .mk::before";
          set = [
            ["content" "\"1m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0102\"] .sub::before";
          set = [
            ["content" "\"Working · 2m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0102\"] .mk::before";
          set = [
            ["content" "\"2m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0103\"] .sub::before";
          set = [
            ["content" "\"Working · 3m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0103\"] .mk::before";
          set = [
            ["content" "\"3m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0104\"] .sub::before";
          set = [
            ["content" "\"Working · 4m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0104\"] .mk::before";
          set = [
            ["content" "\"4m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0105\"] .sub::before";
          set = [
            ["content" "\"Working · 5m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0105\"] .mk::before";
          set = [
            ["content" "\"5m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0106\"] .sub::before";
          set = [
            ["content" "\"Working · 6m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0106\"] .mk::before";
          set = [
            ["content" "\"6m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0107\"] .sub::before";
          set = [
            ["content" "\"Working · 7m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0107\"] .mk::before";
          set = [
            ["content" "\"7m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0108\"] .sub::before";
          set = [
            ["content" "\"Working · 8m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0108\"] .mk::before";
          set = [
            ["content" "\"8m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0109\"] .sub::before";
          set = [
            ["content" "\"Working · 9m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0109\"] .mk::before";
          set = [
            ["content" "\"9m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010A\"] .sub::before";
          set = [
            ["content" "\"Working · 10m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010A\"] .mk::before";
          set = [
            ["content" "\"10m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010B\"] .sub::before";
          set = [
            ["content" "\"Working · 11m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010B\"] .mk::before";
          set = [
            ["content" "\"11m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010C\"] .sub::before";
          set = [
            ["content" "\"Working · 12m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010C\"] .mk::before";
          set = [
            ["content" "\"12m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010D\"] .sub::before";
          set = [
            ["content" "\"Working · 13m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010D\"] .mk::before";
          set = [
            ["content" "\"13m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010E\"] .sub::before";
          set = [
            ["content" "\"Working · 14m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010E\"] .mk::before";
          set = [
            ["content" "\"14m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E010F\"] .sub::before";
          set = [
            ["content" "\"Working · 15m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E010F\"] .mk::before";
          set = [
            ["content" "\"15m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0110\"] .sub::before";
          set = [
            ["content" "\"Working · 16m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0110\"] .mk::before";
          set = [
            ["content" "\"16m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0111\"] .sub::before";
          set = [
            ["content" "\"Working · 17m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0111\"] .mk::before";
          set = [
            ["content" "\"17m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0112\"] .sub::before";
          set = [
            ["content" "\"Working · 18m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0112\"] .mk::before";
          set = [
            ["content" "\"18m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0113\"] .sub::before";
          set = [
            ["content" "\"Working · 19m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0113\"] .mk::before";
          set = [
            ["content" "\"19m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0114\"] .sub::before";
          set = [
            ["content" "\"Working · 20m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0114\"] .mk::before";
          set = [
            ["content" "\"20m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0115\"] .sub::before";
          set = [
            ["content" "\"Working · 21m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0115\"] .mk::before";
          set = [
            ["content" "\"21m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0116\"] .sub::before";
          set = [
            ["content" "\"Working · 22m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0116\"] .mk::before";
          set = [
            ["content" "\"22m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0117\"] .sub::before";
          set = [
            ["content" "\"Working · 23m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0117\"] .mk::before";
          set = [
            ["content" "\"23m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0118\"] .sub::before";
          set = [
            ["content" "\"Working · 24m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0118\"] .mk::before";
          set = [
            ["content" "\"24m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0119\"] .sub::before";
          set = [
            ["content" "\"Working · 25m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0119\"] .mk::before";
          set = [
            ["content" "\"25m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011A\"] .sub::before";
          set = [
            ["content" "\"Working · 26m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011A\"] .mk::before";
          set = [
            ["content" "\"26m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011B\"] .sub::before";
          set = [
            ["content" "\"Working · 27m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011B\"] .mk::before";
          set = [
            ["content" "\"27m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011C\"] .sub::before";
          set = [
            ["content" "\"Working · 28m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011C\"] .mk::before";
          set = [
            ["content" "\"28m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011D\"] .sub::before";
          set = [
            ["content" "\"Working · 29m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011D\"] .mk::before";
          set = [
            ["content" "\"29m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011E\"] .sub::before";
          set = [
            ["content" "\"Working · 30m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011E\"] .mk::before";
          set = [
            ["content" "\"30m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E011F\"] .sub::before";
          set = [
            ["content" "\"Working · 31m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E011F\"] .mk::before";
          set = [
            ["content" "\"31m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0120\"] .sub::before";
          set = [
            ["content" "\"Working · 32m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0120\"] .mk::before";
          set = [
            ["content" "\"32m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0121\"] .sub::before";
          set = [
            ["content" "\"Working · 33m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0121\"] .mk::before";
          set = [
            ["content" "\"33m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0122\"] .sub::before";
          set = [
            ["content" "\"Working · 34m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0122\"] .mk::before";
          set = [
            ["content" "\"34m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0123\"] .sub::before";
          set = [
            ["content" "\"Working · 35m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0123\"] .mk::before";
          set = [
            ["content" "\"35m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0124\"] .sub::before";
          set = [
            ["content" "\"Working · 36m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0124\"] .mk::before";
          set = [
            ["content" "\"36m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0125\"] .sub::before";
          set = [
            ["content" "\"Working · 37m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0125\"] .mk::before";
          set = [
            ["content" "\"37m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0126\"] .sub::before";
          set = [
            ["content" "\"Working · 38m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0126\"] .mk::before";
          set = [
            ["content" "\"38m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0127\"] .sub::before";
          set = [
            ["content" "\"Working · 39m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0127\"] .mk::before";
          set = [
            ["content" "\"39m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0128\"] .sub::before";
          set = [
            ["content" "\"Working · 40m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0128\"] .mk::before";
          set = [
            ["content" "\"40m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0129\"] .sub::before";
          set = [
            ["content" "\"Working · 41m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0129\"] .mk::before";
          set = [
            ["content" "\"41m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012A\"] .sub::before";
          set = [
            ["content" "\"Working · 42m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012A\"] .mk::before";
          set = [
            ["content" "\"42m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012B\"] .sub::before";
          set = [
            ["content" "\"Working · 43m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012B\"] .mk::before";
          set = [
            ["content" "\"43m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012C\"] .sub::before";
          set = [
            ["content" "\"Working · 44m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012C\"] .mk::before";
          set = [
            ["content" "\"44m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012D\"] .sub::before";
          set = [
            ["content" "\"Working · 45m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012D\"] .mk::before";
          set = [
            ["content" "\"45m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012E\"] .sub::before";
          set = [
            ["content" "\"Working · 46m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012E\"] .mk::before";
          set = [
            ["content" "\"46m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E012F\"] .sub::before";
          set = [
            ["content" "\"Working · 47m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E012F\"] .mk::before";
          set = [
            ["content" "\"47m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0130\"] .sub::before";
          set = [
            ["content" "\"Working · 48m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0130\"] .mk::before";
          set = [
            ["content" "\"48m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0131\"] .sub::before";
          set = [
            ["content" "\"Working · 49m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0131\"] .mk::before";
          set = [
            ["content" "\"49m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0132\"] .sub::before";
          set = [
            ["content" "\"Working · 50m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0132\"] .mk::before";
          set = [
            ["content" "\"50m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0133\"] .sub::before";
          set = [
            ["content" "\"Working · 51m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0133\"] .mk::before";
          set = [
            ["content" "\"51m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0134\"] .sub::before";
          set = [
            ["content" "\"Working · 52m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0134\"] .mk::before";
          set = [
            ["content" "\"52m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0135\"] .sub::before";
          set = [
            ["content" "\"Working · 53m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0135\"] .mk::before";
          set = [
            ["content" "\"53m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0136\"] .sub::before";
          set = [
            ["content" "\"Working · 54m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0136\"] .mk::before";
          set = [
            ["content" "\"54m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0137\"] .sub::before";
          set = [
            ["content" "\"Working · 55m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0137\"] .mk::before";
          set = [
            ["content" "\"55m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0138\"] .sub::before";
          set = [
            ["content" "\"Working · 56m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0138\"] .mk::before";
          set = [
            ["content" "\"56m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0139\"] .sub::before";
          set = [
            ["content" "\"Working · 57m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0139\"] .mk::before";
          set = [
            ["content" "\"57m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013A\"] .sub::before";
          set = [
            ["content" "\"Working · 58m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013A\"] .mk::before";
          set = [
            ["content" "\"58m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013B\"] .sub::before";
          set = [
            ["content" "\"Working · 59m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013B\"] .mk::before";
          set = [
            ["content" "\"59m\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013C\"] .sub::before";
          set = [
            ["content" "\"Working · 1h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013C\"] .mk::before";
          set = [
            ["content" "\"1h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013D\"] .sub::before";
          set = [
            ["content" "\"Working · 2h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013D\"] .mk::before";
          set = [
            ["content" "\"2h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013E\"] .sub::before";
          set = [
            ["content" "\"Working · 3h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013E\"] .mk::before";
          set = [
            ["content" "\"3h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E013F\"] .sub::before";
          set = [
            ["content" "\"Working · 4h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E013F\"] .mk::before";
          set = [
            ["content" "\"4h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0140\"] .sub::before";
          set = [
            ["content" "\"Working · 5h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0140\"] .mk::before";
          set = [
            ["content" "\"5h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0141\"] .sub::before";
          set = [
            ["content" "\"Working · 6h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0141\"] .mk::before";
          set = [
            ["content" "\"6h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0142\"] .sub::before";
          set = [
            ["content" "\"Working · 7h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0142\"] .mk::before";
          set = [
            ["content" "\"7h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0143\"] .sub::before";
          set = [
            ["content" "\"Working · 8h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0143\"] .mk::before";
          set = [
            ["content" "\"8h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0144\"] .sub::before";
          set = [
            ["content" "\"Working · 9h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0144\"] .mk::before";
          set = [
            ["content" "\"9h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0145\"] .sub::before";
          set = [
            ["content" "\"Working · 10h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0145\"] .mk::before";
          set = [
            ["content" "\"10h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0146\"] .sub::before";
          set = [
            ["content" "\"Working · 11h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0146\"] .mk::before";
          set = [
            ["content" "\"11h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0147\"] .sub::before";
          set = [
            ["content" "\"Working · 12h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0147\"] .mk::before";
          set = [
            ["content" "\"12h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0148\"] .sub::before";
          set = [
            ["content" "\"Working · 13h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0148\"] .mk::before";
          set = [
            ["content" "\"13h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0149\"] .sub::before";
          set = [
            ["content" "\"Working · 14h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0149\"] .mk::before";
          set = [
            ["content" "\"14h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014A\"] .sub::before";
          set = [
            ["content" "\"Working · 15h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014A\"] .mk::before";
          set = [
            ["content" "\"15h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014B\"] .sub::before";
          set = [
            ["content" "\"Working · 16h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014B\"] .mk::before";
          set = [
            ["content" "\"16h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014C\"] .sub::before";
          set = [
            ["content" "\"Working · 17h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014C\"] .mk::before";
          set = [
            ["content" "\"17h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014D\"] .sub::before";
          set = [
            ["content" "\"Working · 18h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014D\"] .mk::before";
          set = [
            ["content" "\"18h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014E\"] .sub::before";
          set = [
            ["content" "\"Working · 19h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014E\"] .mk::before";
          set = [
            ["content" "\"19h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E014F\"] .sub::before";
          set = [
            ["content" "\"Working · 20h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E014F\"] .mk::before";
          set = [
            ["content" "\"20h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0150\"] .sub::before";
          set = [
            ["content" "\"Working · 21h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0150\"] .mk::before";
          set = [
            ["content" "\"21h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0151\"] .sub::before";
          set = [
            ["content" "\"Working · 22h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0151\"] .mk::before";
          set = [
            ["content" "\"22h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0152\"] .sub::before";
          set = [
            ["content" "\"Working · 23h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0152\"] .mk::before";
          set = [
            ["content" "\"23h\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0153\"] .sub::before";
          set = [
            ["content" "\"Working · 1d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0153\"] .mk::before";
          set = [
            ["content" "\"1d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0154\"] .sub::before";
          set = [
            ["content" "\"Working · 2d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0154\"] .mk::before";
          set = [
            ["content" "\"2d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0155\"] .sub::before";
          set = [
            ["content" "\"Working · 3d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0155\"] .mk::before";
          set = [
            ["content" "\"3d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0156\"] .sub::before";
          set = [
            ["content" "\"Working · 4d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0156\"] .mk::before";
          set = [
            ["content" "\"4d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0157\"] .sub::before";
          set = [
            ["content" "\"Working · 5d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0157\"] .mk::before";
          set = [
            ["content" "\"5d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0158\"] .sub::before";
          set = [
            ["content" "\"Working · 6d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0158\"] .mk::before";
          set = [
            ["content" "\"6d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0159\"] .sub::before";
          set = [
            ["content" "\"Working · 7d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0159\"] .mk::before";
          set = [
            ["content" "\"7d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015A\"] .sub::before";
          set = [
            ["content" "\"Working · 8d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015A\"] .mk::before";
          set = [
            ["content" "\"8d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015B\"] .sub::before";
          set = [
            ["content" "\"Working · 9d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015B\"] .mk::before";
          set = [
            ["content" "\"9d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015C\"] .sub::before";
          set = [
            ["content" "\"Working · 10d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015C\"] .mk::before";
          set = [
            ["content" "\"10d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015D\"] .sub::before";
          set = [
            ["content" "\"Working · 11d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015D\"] .mk::before";
          set = [
            ["content" "\"11d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015E\"] .sub::before";
          set = [
            ["content" "\"Working · 12d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015E\"] .mk::before";
          set = [
            ["content" "\"12d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E015F\"] .sub::before";
          set = [
            ["content" "\"Working · 13d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E015F\"] .mk::before";
          set = [
            ["content" "\"13d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0160\"] .sub::before";
          set = [
            ["content" "\"Working · 14d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0160\"] .mk::before";
          set = [
            ["content" "\"14d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0161\"] .sub::before";
          set = [
            ["content" "\"Working · 15d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0161\"] .mk::before";
          set = [
            ["content" "\"15d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0162\"] .sub::before";
          set = [
            ["content" "\"Working · 16d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0162\"] .mk::before";
          set = [
            ["content" "\"16d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0163\"] .sub::before";
          set = [
            ["content" "\"Working · 17d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0163\"] .mk::before";
          set = [
            ["content" "\"17d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0164\"] .sub::before";
          set = [
            ["content" "\"Working · 18d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0164\"] .mk::before";
          set = [
            ["content" "\"18d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0165\"] .sub::before";
          set = [
            ["content" "\"Working · 19d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0165\"] .mk::before";
          set = [
            ["content" "\"19d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0166\"] .sub::before";
          set = [
            ["content" "\"Working · 20d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0166\"] .mk::before";
          set = [
            ["content" "\"20d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0167\"] .sub::before";
          set = [
            ["content" "\"Working · 21d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0167\"] .mk::before";
          set = [
            ["content" "\"21d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0168\"] .sub::before";
          set = [
            ["content" "\"Working · 22d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0168\"] .mk::before";
          set = [
            ["content" "\"22d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0169\"] .sub::before";
          set = [
            ["content" "\"Working · 23d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0169\"] .mk::before";
          set = [
            ["content" "\"23d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016A\"] .sub::before";
          set = [
            ["content" "\"Working · 24d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016A\"] .mk::before";
          set = [
            ["content" "\"24d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016B\"] .sub::before";
          set = [
            ["content" "\"Working · 25d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016B\"] .mk::before";
          set = [
            ["content" "\"25d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016C\"] .sub::before";
          set = [
            ["content" "\"Working · 26d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016C\"] .mk::before";
          set = [
            ["content" "\"26d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016D\"] .sub::before";
          set = [
            ["content" "\"Working · 27d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016D\"] .mk::before";
          set = [
            ["content" "\"27d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016E\"] .sub::before";
          set = [
            ["content" "\"Working · 28d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016E\"] .mk::before";
          set = [
            ["content" "\"28d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E016F\"] .sub::before";
          set = [
            ["content" "\"Working · 29d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E016F\"] .mk::before";
          set = [
            ["content" "\"29d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working[title*=\"\\E0170\"] .sub::before";
          set = [
            ["content" "\"Working · 30d\" !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not(.working)[title*=\"\\E0170\"] .mk::before";
          set = [
            ["content" "\"30d\" !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_card.css" = generators.sourceFile "rail_card.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt";
          set = [
            ["border-radius" "8px !important"]
            ["box-shadow" "none !important"]
            ["color" "var(--t3) !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:hover";
          set = [
            ["background" "color-mix(in srgb, var(--t1) 6%, transparent) !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.on";
          set = [
            ["background" "var(--panel) !important"]
            ["box-shadow" "inset 0 0 0 1px var(--l2) !important"]
            ["color" "var(--t1) !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.on .nm";
          set = [
            ["font-weight" "600"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.on::before, html.lay-rail.tabs-h .tb-tabs .tt.on::after";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_compact.css" = generators.sourceFile "rail_compact.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt";
          set = [
            ["height" "38px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206E\"]:not([data-tc])";
          set = [
            ["height" "20px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206E\"]:not([data-tc]) .sub";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_header.css" = generators.sourceFile "rail_header.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in";
          set = [
            ["position" "relative !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in > .tb-add, html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge";
          set = [
            ["position" "absolute !important"]
            ["top" "4px !important"]
            ["width" "28px !important"]
            ["height" "26px !important"]
            ["margin" "0 !important"]
            ["padding" "0 !important"]
            ["justify-content" "center !important"]
            ["gap" "0 !important"]
            ["border-radius" "7px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in > .tb-add";
          set = [
            ["right" "40px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge";
          set = [
            ["right" "8px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in > :is(.tb-add, .tn-ib-badge) :is(.lbl, .kbds)";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge .tn-ib-pip";
          set = [
            ["position" "absolute !important"]
            ["top" "1px !important"]
            ["right" "1px !important"]
            ["margin" "0 !important"]
            ["transform" "scale(0.8)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_sections.css" = generators.sourceFile "rail_sections.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt";
          set = [
            ["position" "relative"]
            ["overflow" "visible !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt::before, html.lay-rail.tabs-h .tb-tabs .tt::after";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"], html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]";
          set = [
            ["margin-top" "34px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"]::after, html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]::after";
          set = [
            ["display" "block !important"]
            ["position" "absolute"]
            ["left" "10px"]
            ["top" "-26px"]
            ["width" "auto"]
            ["height" "auto"]
            ["background" "none"]
            ["box-shadow" "none"]
            ["font-size" "11px"]
            ["font-weight" "600"]
            ["letter-spacing" "0.06em"]
            ["text-transform" "uppercase"]
            ["color" "var(--t4)"]
            ["pointer-events" "none"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2061\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2061\"]) + .tt[title^=\"\\2061\"]::after";
          set = [
            ["content" "\"Pinned\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2062\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2062\"]) + .tt[title^=\"\\2062\"]::after";
          set = [
            ["content" "\"Needs you\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2063\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2063\"]) + .tt[title^=\"\\2063\"]::after";
          set = [
            ["content" "\"Working\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title^=\"\\2064\"]:first-child::after, html.lay-rail.tabs-h .tb-tabs .tt:not([title^=\"\\2064\"]) + .tt[title^=\"\\2064\"]::after";
          set = [
            ["content" "\"Idle\""]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/rail_status.css" = generators.sourceFile "rail_status.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk::before, html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk::after";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c";
          set = [
            ["position" "relative"]
            ["overflow" "visible !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c[data-st='working']::before";
          set = [
            ["inset" "-4px"]
            ["box-sizing" "border-box"]
            ["border" "2px dashed var(--pill)"]
            ["border-radius" "50%"]
            ["animation" "arc-spin 2.4s linear infinite"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]):is([title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .tn-dk-c::before";
          set = [
            ["content" "\"\""]
            ["position" "absolute"]
            ["border-radius" "50%"]
            ["pointer-events" "none"]
            ["right" "-3px"]
            ["bottom" "-3px"]
            ["width" "10px"]
            ["height" "10px"]
            ["background" "var(--pill)"]
            ["box-shadow" "0 0 0 2px var(--panel)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub";
          set = [
            ["font-size" "0 !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub::before";
          set = [
            ["font-size" "12px"]
            ["font-weight" "500"]
            ["font-family" "var(--sans)"]
            ["color" "var(--pill)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working";
          set = [
            ["--pill" "light-dark(#0f766e, #5eead4)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt.working .sub::before";
          set = [
            ["content" "\"Working\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206B\"]";
          set = [
            ["--pill" "light-dark(#b45309, #fbbf24)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206B\"] .sub::before";
          set = [
            ["content" "\"Awaiting input\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206C\"]";
          set = [
            ["--pill" "light-dark(#15803d, #4ade80)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206C\"] .sub::before";
          set = [
            ["content" "\"Done · unseen\""]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206D\"]";
          set = [
            ["--pill" "light-dark(#b91c1c, #f87171)"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt[title*=\"\\206D\"] .sub::before";
          set = [
            ["content" "\"Failed · unseen\""]
          ];
        }
        {
          at = "@keyframes arc-spin";
          rules = [
            {
              select = "from";
              set = [
                ["transform" "rotate(0deg)"]
              ];
            }
            {
              select = "to";
              set = [
                ["transform" "rotate(360deg)"]
              ];
            }
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:not([data-tc]) .tn-dk-c::after";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub > *";
          set = [
            ["display" "none !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h .tb-tabs .tt:is(.working, [title*=\"\\206B\"], [title*=\"\\206C\"], [title*=\"\\206D\"]) .sub::after";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/roomy.css" = generators.sourceFile "roomy.css" (generators.cssSource [
        {
          select = "html.tn-themed #pick .cmdk.tn-pk";
          set = [
            ["display" "flex"]
            ["flex-direction" "column"]
            ["max-height" "calc(87vh - 24px) !important"]
          ];
        }
        {
          select = "html.tn-themed #pick .cmdk.tn-pk > .ck-top, html.tn-themed #pick .cmdk.tn-pk > .ck-foot";
          set = [
            ["flex" "none"]
          ];
        }
        {
          select = "html.tn-themed #pick .cmdk.tn-pk .ck-list";
          set = [
            ["max-height" "none !important"]
            ["min-height" "0"]
            ["flex" "1 1 auto"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/row-keys.css" = generators.sourceFile "row-keys.css" (generators.cssSource [
        {
          select = "html.lay-rail #tabbar .tb-row .kbds";
          set = [
            ["display" "none"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/scratch.css" = "${flakeInputs.tern-scratch}/min.css";
      "plugins/ui-menu/snippets/single.css" = generators.sourceFile "single.css" (generators.cssSource [
        {
          select = ".tn-session-tab, .tn-vt > .nav-group:is(.g-sp, .g-sp-cur) > .nav-head, .tn-pl-scope[title^='Sessions']";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/tabs.css" = generators.sourceFile "tabs.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h .tt.on";
          set = [
            ["box-shadow" "inset 2px 0 0 var(--accent) !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/transparent.css" = generators.sourceFile "transparent.css" (generators.cssSource [
        {
          select = "html.tn-themed, html.tn-themed.glass";
          set = [
            ["--page" "transparent"]
            ["--panel" "transparent"]
            ["--tn-page-a" "0"]
            ["--tn-panel-a" "0"]
            ["--surface-a" "0"]
            ["--tv-bg" "transparent"]
            ["--modal-filter" "none"]
            ["--modal-dim-filter" "none"]
            ["background" "transparent !important"]
          ];
        }
        {
          select = "html.tn-themed *, html.tn-themed *::before, html.tn-themed *::after";
          set = [
            ["backdrop-filter" "none !important"]
            ["-webkit-backdrop-filter" "none !important"]
          ];
        }
        {
          select = "html.tn-themed body, html.tn-themed .tn-body, html.tn-themed .tn-head, html.tn-themed #panel, html.tn-themed #sidebar, html.tn-themed #tabbar, html.tn-themed #statusline";
          set = [
            ["background" "transparent"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/turn-stats.css" = generators.sourceFile "turn-stats.css" (generators.cssSource [
        {
          select = "html.tn-themed [data-role='omp.turn.usage']";
          set = [
            ["display" "none !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/user-frost.css" = generators.sourceFile "user-frost.css" (generators.cssSource [
        {
          select = ":root:not(#s0):not(#s1) [data-role='omp.chat.msg'] .sf-card[data-role='omp.user'] > .sf-card-body";
          set = [
            ["background" "var(--frost-you-fill, var(--frost-fill))"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
            ["box-shadow" "var(--frost-edge)"]
            ["--t1" "var(--frost-you-ink, var(--frost-ink))"]
            ["color" "var(--frost-you-ink, var(--frost-ink))"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/composer-frost.css" = generators.sourceFile "composer-frost.css" (generators.cssSource [
        {
          select = ":root:not(#s0):not(#s1) [data-role='omp.chat.dock'] .sf-col[data-role^='omp.editor'], :root:not(#s0):not(#s1) [data-role='omp.bot.dock'] .sf-col[data-role^='omp.editor']";
          set = [
            ["background" "var(--frost-fill)"]
            ["-webkit-backdrop-filter" "var(--frost) !important"]
            ["backdrop-filter" "var(--frost) !important"]
            ["box-shadow" "var(--frost-edge)"]
            ["--t1" "var(--frost-ink)"]
            ["color" "var(--frost-ink)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/width.css" = generators.sourceFile "width.css" (generators.cssSource [
        {
          select = "html.lay-rail.tabs-h #tabbar";
          set = [
            ["width" "236px !important"]
          ];
        }
        {
          select = "html.lay-rail.tabs-h #panel";
          set = [
            ["left" "calc(236px * var(--tn-zoom, 1)) !important"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/work-rail.css" = generators.sourceFile "work-rail.css" (generators.cssSource [
        {
          select = ".sf-chat-reader [data-role='omp.assistant.note'] > .sf-md .md";
          set = [
            ["font-size" "13px"]
            ["color" "var(--t2)"]
          ];
        }
        {
          select = ".sf-chat-reader [data-role='omp.assistant.note'] > .sf-md .md > :last-child";
          set = [
            ["margin-bottom" "0"]
          ];
        }
        {
          select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-head";
          set = [
            ["font-size" "13px"]
            ["color" "var(--t2)"]
          ];
        }
        {
          select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-head .sf-t-dim";
          set = [
            ["color" "var(--t4)"]
          ];
        }
        {
          select = ".sf-chat-reader .sf-section[data-role='omp.notice.work'] > .sf-section-body";
          set = [
            ["margin-left" "7px"]
            ["padding-left" "15px"]
            ["box-shadow" "inset 1px 0 0 var(--l2)"]
          ];
        }
      ]);
      "plugins/ui-menu/snippets/yorha-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-you.css" = "${flakeInputs.tern-ozette}/yorha-bot-you.css";
      "plugins/ui-menu/snippets/yorha.css" = "${flakeInputs.tern-ozette}/yorha.css";
      "plugins/ui-menu/snippets/grok.css" = "${flakeInputs.tern-ozette}/grok.css";
      "plugins/ui-menu/snippets/grok-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-user-bubbles.css" = "${flakeInputs.tern-ozette}/grok-user-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-you.css" = "${flakeInputs.tern-ozette}/grok-bot-you.css";
      "plugins/ui-menu/snippets/departure.css" = "${flakeInputs.tern-ozette}/departure.css";
      "plugins/ui-menu/snippets/automata.css" = "${flakeInputs.tern-ozette}/automata.css";
      "plugins/ui-menu/snippets/botanical.css" = "${flakeInputs.tern-ozette}/botanical.css";
      "plugins/ui-menu/snippets/braun.css" = "${flakeInputs.tern-ozette}/braun.css";
      "plugins/ui-menu/snippets/folio.css" = "${flakeInputs.tern-ozette}/folio.css";
      "plugins/ui-menu/snippets/blueprint.css" = "${flakeInputs.tern-ozette}/blueprint.css";
      "plugins/ui-menu/snippets/eink.css" = "${flakeInputs.tern-ozette}/eink.css";
      "plugins/ui-menu/snippets/phosphor.css" = "${flakeInputs.tern-ozette}/phosphor.css";
      "plugins/ui-menu/window.luau" = ./config/plugins/ui-menu/window.luau;
      "settings.json" = ./config/settings.json;
    }
    // lib.mapAttrs (name: path: builtins.toFile (builtins.baseNameOf name) "${path}\n") pluginPaths;

  devTree = "${config.user.homeDirectory}/dev";

  devLinks = lib.filterAttrs (_: path: lib.hasPrefix "${devTree}/" path) pluginPaths;

  orphans =
    if lib.hasAttr devTree config.fileSystems
    then {}
    else devLinks;

  files =
    lib.mapAttrs' (name: file:
      lib.nameValuePair ".config/tern/${name}" {
        type = "copy";
        clobber = false;
        force = false;
        permissions = "0644";
        source = file;
      }) (removeAttrs configFiles (lib.attrNames orphans))
    // lib.mapAttrs' (name: _: lib.nameValuePair ".config/tern/${name}" {type = "delete";}) orphans;

  ternPeers = {
    y0usaf-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6ZHkn1pACV406TM5yUCRt/874vybgpUW3sUKka9nAC y0usaf@y0usaf-desktop";
    y0usaf-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjN9qndKm1iN0ctrucDNRBkfcZqC7zbRKR8SCD9E7KW y0usaf@y0usaf-server";
  };

  waitForMount = path: ''
    for _ in $(seq 1 20); do
      ${pkgs.util-linux}/bin/findmnt -n -o TARGET --mountpoint "${path}" >/dev/null 2>&1 && break
      sleep 0.5
    done
  '';

  remoteServe = pkgs.writeShellScript "tern-remote-serve" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    ${waitForMount "${config.user.homeDirectory}/.config/tern"}
    ${waitForMount "${config.user.homeDirectory}/.local/state/tern"}
    exec ${package}/bin/tern remote serve --user --state-dir ${config.user.homeDirectory}/.config/tern
  '';

  seedAuthorizedKeys =
    pkgs.writeShellScript "tern-seed-authorized-keys" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gawk]}
      ${waitForMount "${config.user.homeDirectory}/.ssh"}
      dir="$HOME/.ssh"
      mkdir -p "$dir"
      chmod 0700 "$dir"
      auth="$dir/authorized_keys"
      touch "$auth"
      chmod 0600 "$auth"
      add() {
        kind="''${1%% *}"
        blob="$(printf '%s' "$1" | cut -d' ' -f2)"
        if awk -v k="$kind" -v b="$blob" '$1 == k && $2 == b { found = 1 } END { exit !found }' "$auth"; then
          return 0
        fi
        printf '%s\n' "$1" >> "$auth"
      }
      ${lib.concatMapStringsSep "
" (key: "add '${key}'") (lib.attrValues (lib.removeAttrs ternPeers [config.networking.hostName]))}
    '';
in {
  environment.variables.GIO_EXTRA_MODULES = lib.mkDefault "${pkgs.glib-networking}/lib/gio/modules";

  user.persist.directories = [
    ".config/tern"
    ".local/state/tern"
    ".local/state/brain"
    ".local/state/cmus-tsp"
    ".local/state/so.stencil.tern"
  ];

  user.files = files // tuturu;

  finit = {
    tmpfiles.rules = ["d ${config.user.runtimeDir} 0700 ${config.user.name} users"];

    tasks.tern-authorized-keys = {
      description = "seed ~/.ssh/authorized_keys for tern remote (${config.user.name})";
      user = config.user.name;
      environment.HOME = config.user.homeDirectory;
      command = seedAuthorizedKeys;
    };

    services.tern-remote = {
      description = "Tern remote sessions (${config.user.name})";
      user = config.user.name;
      environment = {
        HOME = config.user.homeDirectory;
        XDG_RUNTIME_DIR = config.user.runtimeDir;
      };
      command = remoteServe;
      conditions = ["net/lo/up" "task/tmpfiles-setup/success"];
      log = true;
    };
  };

  environment.systemPackages = [package cmusTsp];
}
