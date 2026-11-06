{
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
    ["Tern is a closed binary from build.stencil.so, installed by " (code "~/finix/modules/tools/tern/default.nix") " (0.9.11, commit f93bb18); plugin docs at docs.stencil.so/tern, layout guide at " (code "guides/layout.html") ". Its layout is fixed policy: the arrangement verbs are new_tab/split/focus/close/move/resize/tab — no placement verb, no rects."]
    ["His reference terminals are his own: Ekko (" (code "~/dev/maintaining/ekko") ", Common Lisp, gets its deck from " (code "place-panes") "/layout providers) and Cudaterm (" (code "~/dev/maintaining/cudaterm") ")."]
    ["Measured 2026-10-29: CSS moves a pane's box (front " (code "[349,0,2174,1388]") ", back " (code "[-3000,0,2174,1388]") ") but the PTY grid stays at its split size (95×63) — Tern sizes panes from its split math, not the DOM box, so CSS is chrome only and there is no in-window deck; parking reflows PTYs. Untested lead: picture-in-picture panes place in corners, dock to edges and can be hidden (\"Hide pictures in picture\") — worth testing whether a hidden PiP keeps its grid size."]
    ["Measuring habits that work: stub-load " (code "window.luau") " in the Lua VM (" (code "loadstring('return function(tern) ' .. src .. ' end')()") ") to unit-test handlers; " (code "tern ctl dump") " (~11 MB JSON, run inside a Tern pane) for DOM geometry; " (code "tern inspect --json") " for every pane's cols/rows; a scratch shell pane via " (code "cx.layout:split(target, dir, { command = 'sh' })") ". " (code "tern ctl state") " describes only the shown tab and calls the tab list " (code "decks") "; " (code "cx.layout:new_tab()") " returns the new pane id, not the tab id."]
    ["My own memory flush fails with " (code "No API key found for google-vertex") " (seen 2026-10-29 22:55); workspace writes still work."]
    [(strong "PR3544") " is a review of the tlc webhooks PR, checked out at " (code "/tmp/tlc") "."]
  ])
]
