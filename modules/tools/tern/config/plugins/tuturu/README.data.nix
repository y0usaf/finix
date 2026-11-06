{
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
]
