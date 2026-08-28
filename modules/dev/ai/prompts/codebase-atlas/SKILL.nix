''
---
name: codebase-atlas
description: Turn a codebase into an interactive isometric architecture map written as a single self-contained HTML file, in the hatched drafting-paper style with hover descriptions, animated data-flow dots, go-inside drill-downs, and a step-by-step request trace. Use when the user says "make a codebase atlas", "make one for my codebase", "turn this repo into a visual diagram", "isometric codebase map", "visual map of the architecture", or points at a FleetingBits-style isometric codebase screenshot and asks for the same. Also use to update or extend an existing atlas. Not for single mechanism diagrams inside a prose answer (draw inline SVG), Mermaid/flowchart requests, or UI mockups of the product itself.
---

# Codebase Atlas

Produce a single self-contained HTML page (no external deps, CSP-safe) that maps a repository as
an isometric city: blocks sized by real line counts, edges carrying animated data dots, a left
structure rail, and a right WHAT IT DOES / HOW IT'S BUILT panel. Write it as a single HTML file.

## Step 1: Inventory the repo (facts, not guesses)

Spawn an Explore agent (very thorough) asking for a structured inventory:

- 15-35 major subsystems, each with: short name, directory/key files, 1-2 plain-English sentences
for a non-expert, rough size (files or LOC), and what it talks to (directed edges with what flows).
- Overall request flow, databases/storage, headline stats (total LOC, routers/routes, feature
counts, test files, deployed services).
- Ask it to correct your assumed subsystem list, and to distinguish deployed **services** from
code-level **roles**

Every number shown in the atlas must come from this scan. Never invent counts.

## Step 2: Build from the template engine

Copy `references/atlas-template.html` (the finished CordComputer atlas) into the session scratchpad
and keep the engine; replace only the DATA section near the top of the script:

- `STRUCTURES`: id, 2-char code, name, group, loc label, grid pos `gx,gy`, footprint `w,d`,
height `h` (scale by LOC), `what`, `how`, `talks[]`, optional `children[]` (code, name, h, what)
for go-inside views, optional `slab:true` for flat storage blocks.
- `EDGES`: `{f, t, flow:1}` for animated main-path edges, `dashed:1` for advisory/CI edges,
`pay` names what travels (shown when hovering a dot), optional `via:[[gx,gy]...]` waypoints.
- `EXTERNALS`: off-map labels with dashed leaders (LLM providers, SaaS APIs, uploads).
- `TRACE`: 10-14 `[structId, sentence]` steps walking one canonical request end to end.
- Topbar stats, sidebar `GROUPS`, and the two overview essays (`OVERVIEW_WHAT`, `OVERVIEW_HOW`).

Layout rules that make it read well:

- Iso projection is `x=(gx-gy)*26, y=(gx+gy)*14.3 - h*16`. Keep block footprints disjoint;
painter order sorts by `gx+gy` so nothing needs z-hacks.
- Cluster by zone: browser surfaces top, API below them, agent right, ingestion left, core domain
center, compute below it, storage slabs bottom row, CI in a corner.
- Default edge routing is an L-elbow; add `via` waypoints only when a line would cut through an
unrelated cluster. Lines hidden under blocks are acceptable.
- Biggest subsystem = tallest block. Storage = flat slabs. The eye should find the core domain
in the middle.

## Step 3: Verify headlessly before finishing

The template has a URL-hash debug hook. Screenshot at 1800x1000 with
`npx --yes playwright screenshot` against `file://...` for at least: the default view, one
`#inside=<id>` view, and `#trace=7`. Look for label collisions, external labels clipping,
orphaned blocks, and edges slicing through clusters. Fix, reshoot, then write the final HTML file
(favicon 🗺️, keep it stable across rewrites).

## Step 4: Share-safety pass (always, before the user posts it)

The atlas may leave the company. Keep code structure (module names, LOC, stack); scrub anything
that describes live infrastructure: concrete cloud service/queue names, public endpoint paths,
API-key prefixes or formats, where credentials are stored, project IDs, resource shapes. Grep the
final file for the company's cloud naming prefix, `@`, `secret`, key prefixes, and mount paths.
Remind the user the HTML file stays private until they share it from the page menu.
''
