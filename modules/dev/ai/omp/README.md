# omp transcript presentation

In Tern, omp's transcript gives each thing one level of attention:

- **The answer** that ends a turn sits in a bubble on the left, opposite your messages on the right.
- **Work** folds into one row per stretch of steps. A row leads with the sentence the model wrote before those steps, then the step count and time; a row with no such sentence reads **Worked for …**. It stays open while it runs and folds when the next sentence or the answer arrives. Folded, the sentence is cut to one line; open, it wraps in full with its links. Open the row for the model's reasoning, any further paragraphs and each step; open a step for its code and output.
- **Turn stats** (time, tokens, cost under each answer) are hidden by **hide turn stats** in Tern's UI options block; untick it to bring them back.
- **Failures** show as a red count on their row. A failed step stays listed under the folded row only when the turn ended on it.
- **Notices** from omp and extensions keep their own small rows, inside a work row when they land mid-work.

The pieces:

- [code-mode.ts](code-mode.ts) asks for a short title on every eval cell, which becomes the step's name.
- [compact-eval.ts](compact-eval.ts) folds eval steps to their title, drops language badges, and names untitled steps after the tool they call or their first line.
- [work-fold.ts](work-fold.ts) builds the rows. Your messages, skill and collab prompts, `!`/`$` commands and compaction markers start a new stretch.
- [../../../tools/tern/config/plugins/omp-chat](../../../tools/tern/config/plugins/omp-chat) is the Tern stylesheet for the answer bubble, the quieter sentences and the rail under an open row.

omp is pinned by Nix, so its startup update check is off.

Restart existing omp sessions after changing the extensions; `tern plugin reload` picks up the stylesheet. They use omp's exported UI internals and Tern's Reader classes; after upgrading either, check a running turn, a finished turn, an opened row, a notice between two steps and a success → failure → success turn.
