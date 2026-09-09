---
name: grounded-citations
description: "Use when producing sourced research or fact-check reports."
version: 1.3.0
---

# Grounded citations: compact core

Use for research, externally sourced comparisons, fact-checking, and reports where traceable attribution is part of the deliverable. Do not load for incidental syntax/version lookups during coding, local system/config audits, creative writing, or casual conversation. Ordinary sourced answers still need accurate links and clear uncertainty; skipping this workflow does not waive grounding.

## Evidence rules
- Cite retrieved sources that actually support the adjacent claim; never invent URLs, quotations, IDs, or retrieval results.
- Read the source body when the claim exceeds what the search snippet says. Prefer primary sources for factual claims; label community reports as reports, not measurements.
- Distinguish evidence from inference, preserve exact figures/dates/names, and disclose coverage gaps and disagreements.
- Match research breadth to the question. Do not automatically fan out across platforms or spawn agents for a small lookup.
- For medical, legal, financial, safety-related, disputed, or explicitly fact-checked claims, preserve supporting verbatim text and independently corroborate consequential disputed facts where feasible. Mark genuinely unsupported load-bearing claims as unverified, not as sourced.

## Ledger workflow for research deliverables
The existing stdlib script is `scripts/sources.py` relative to this skill directory. Use `python3` and its `--help` for exact syntax. Keep a task-specific ledger via `--ledger PATH` or `HERMES_CITATION_LEDGER`; never reset a ledger another task is using.

1. Register URLs from retrieval output before drafting: `add URL --title TITLE` or `ingest results.json`. Reuse IDs when continuing a draft.
2. Cite the returned IDs next to supported sentences, at most three IDs per sentence. Do not manufacture IDs or hand-renumber them.
3. Generate the source list with `render --cited-in draft.md`; do not reconstruct URLs from memory.
4. Run `verify draft.md`, fix errors, and rerun before delivery. Verification checks ledger consistency, not factual truth or entailment; inspect support yourself.
5. For evidence-grade work use `quote ID --text 'verbatim wording' --from page.txt`, then `verify draft.md --evidence`; quotes must come from extracted page text. Preserve claim → source → supporting quote.

## Details only when needed
- `references/detailed-guide.md`: command table, evidence mode, verification coverage, multi-source procedure, and pitfalls. Load before using advanced ledger options.
- `references/citation-formats.md`: document-specific citation placement.
- `references/grounding-rationale.md`: rationale, not required for ordinary execution.

Do not load the full guide automatically. Do not reload this core while it remains in context; reload after pruning if needed.
