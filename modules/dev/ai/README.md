# omp transcript presentation

In Tern, omp's transcript separates three things:

- **What the model says** sits in a bubble on the left, opposite your messages on the right.
- **Work** between two things the model says folds into one row: **Working** while it runs, **Worked for … · N steps** once it is done. Open the row to see each step, thought and notice in order; open a step to see its code and output. Failed steps stay listed under the folded row, which carries a failure count.
- **Notices** from omp and extensions keep their own small rows, inside the work row when they land mid-work.

The pieces:

- [omp-compact-eval.ts](omp-compact-eval.ts) folds eval steps to their title, drops language badges, names multi-cell steps after their first cell and opens failures.
- [omp-work-fold.ts](omp-work-fold.ts) groups work into rows. Your messages, skill and collab prompts, `!`/`$` commands and compaction markers start a new stretch; model prose ends one.
- [../../tools/tern/plugins/omp-chat](../../tools/tern/plugins/omp-chat) is the Tern stylesheet for the bubbles and the rail under an open work row.

Restart existing omp sessions after changing the extensions; `tern plugin reload` picks up the stylesheet. They use omp's exported UI internals and Tern's Reader classes; after upgrading either, check a running turn, a finished turn, an expanded row, a notice between two steps and a success → failure → success turn.
