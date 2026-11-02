# omp transcript presentation

In Tern, each turn's work sits under one **Working** row while it runs and folds to **Worked for …** once the turn ends, with the answer below it. Open the row to see every step, thought and note in order; open a step to see its code and output. Failed steps stay listed under the folded row, and the row carries a failure count.

The presentation extensions are loaded by [omp.nix](omp.nix) and [omp-box.nix](omp-box.nix):

- [omp-compact-eval.ts](omp-compact-eval.ts) folds eval steps to their title, drops language badges, names multi-cell steps after their first cell and opens failures.
- [omp-work-fold.ts](omp-work-fold.ts) groups each turn's work into the activity row.

Restart existing omp sessions after changing these extensions. They use omp's exported UI internals; after upgrading omp, check a running turn, a finished turn, an expanded row and a success → failure → success turn in Tern.
