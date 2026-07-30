// loop-next workflow for pi-extensible-workflows.
// Runs the project's `next` skill repeatedly — each iteration is a fresh
// sub-agent context — until PLAN.md has no unchecked boxes.
//
// Stops at:
//   1. plan complete (worker greps PLAN.md: zero unchecked boxes),
//   2. a step that cannot commit (broken tree/build — fix before rerun),
//   3. the iteration cap (args.maxSteps, default 30, hard max 100),
//   4. the run budget, if one was set at launch (slash command cannot
//      pass one; use the workflow tool for a token/cost backstop).
//
// Launch args (none, a bare count via `/loop-next 10`, or JSON):
//   maxSteps?: number (default 30, max 100)

const raw = args == null ? {} : typeof args === "string" ? { maxSteps: args } : args;
if (typeof raw !== "object" || Array.isArray(raw) || raw === null) {
  throw new Error('loop-next expects no args, a step count, or { "maxSteps": number }');
}
const parsed = Number(raw.maxSteps);
const maxSteps = Number.isFinite(parsed) && parsed > 0 ? Math.min(Math.floor(parsed), 100) : 30;

const WORKER_SCHEMA = {
  type: "object",
  properties: {
    summary: {
      type: "string",
      description: "What landed this step plus anything the next step must know",
    },
    openBoxes: {
      type: "number",
      description: "Exact count of unchecked '[ ]' items in PLAN.md, from grep",
    },
    committed: {
      type: "boolean",
      description: "Whether this step's work was committed",
    },
  },
  required: ["summary", "openBoxes", "committed"],
  additionalProperties: false,
};

const WORKER_PROMPT = [
  "Work through this project's `next` skill exactly as written.",
  "Load it from your skill list now and follow all of it: review the past",
  "step, implement the next open PLAN.md item, then close the loop (update",
  "PLAN.md, commit, fold the handoff into PLAN.md).",
  "",
  "Before finishing, run: grep -c '\\[ \\]' PLAN.md || true",
  "Report that exact count as openBoxes (0 means the plan is complete).",
  "If you could not commit your work, set committed to false and explain",
  "why in summary.",
].join("\n");

const history = [];

for (let i = 1; i <= maxSteps; i++) {
  await phase("step-" + String(i));

  const step = await agent(WORKER_PROMPT, {
    label: "next-" + String(i),
    outputSchema: WORKER_SCHEMA,
  });
  history.push("step " + String(i) + ": " + step.summary);

  if (step.openBoxes === 0) {
    return "PLAN.md complete after " + String(i) + " step(s).\n\n" + history.join("\n");
  }
  if (step.committed === false) {
    return "Step " + String(i) + " failed to commit; stopping early.\n\n" + history.join("\n");
  }
}

return (
  "Hit the " +
  String(maxSteps) +
  "-step cap and PLAN.md still has open boxes. Inspect the repo, fix the blocker, rerun.\n\n" +
  history.join("\n")
);
