# omp transcript presentation

Enable **Fold tool calls** in Tern to group consecutive tool calls and thoughts above the answer. Open the group to inspect its steps; open a step to inspect its code and output. Visible assistant text separates groups.

The presentation extensions are loaded by [omp.nix](omp.nix) and [omp-box.nix](omp-box.nix):

- [omp-compact-eval.ts](omp-compact-eval.ts) folds successful eval bodies and opens failures.
- [omp-work-fold.ts](omp-work-fold.ts) omits empty assistant blocks from native transcripts and keeps failed calls outside work groups so their errors remain visible.

Restart existing omp sessions after changing these extensions. They use omp's exported UI internals; verify folded work, expanded steps, and a success → failure → success turn in Tern after upgrading omp.
