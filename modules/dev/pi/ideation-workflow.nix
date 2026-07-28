{
  config,
  lib,
  ...
}: {
  # Multi-model ideation debate workflow for pi-extensible-workflows.
  # Ships the workflow script declaratively to a stable home path so agents
  # can launch it via scriptPath without depending on a repo checkout.
  # Source of truth for edits: this file (the copy in pi-flake's
  # workflows/ideation/ is a development mirror and may drift).
  config = lib.mkIf config.user.dev.pi.enable {
    manzil.users."${config.user.name}".files.".local/share/pi/workflows/ideate.js".text = ''
      // Ideation workflow for pi-extensible-workflows.
      // Multi-model debate: every participant is a plain "ideator" — no personas.
      // Diversity comes from different model weights/corpora, not role prompts.
      //
      // Each round runs in two passes:
      //   1. chain — ideators speak sequentially; each sees everything said before
      //      them this round and must engage it (attack, defend, concede, merge).
      //   2. open floor — everyone sees the full chain and answers the strongest
      //      objection to their own position (sequential: parallel() needs a static
      //      tasks record, which a dynamic model list cannot provide).
      // A judge agent with a structured verdict checks consensus after each round.
      //
      // The loop stops at consensus, a hard round cap, or a human checkpoint.
      //
      // Launch args (JSON):
      //   topic: string (required)
      //   context?: string
      //   maxRounds?: 1-10 (default 5)
      //   models?: string[] — ideator model ids (default: cheap gateway models)
      //   judgeModel?: string — defaults to kimi-k3-fast via vercel-ai-gateway

      if (!args || typeof args.topic !== "string" || !args.topic.trim()) {
        throw new Error('ideate requires args.topic (non-empty string), e.g. { topic: "local-first sync engine" }');
      }

      const topic = args.topic.trim();
      const context = typeof args.context === "string" ? args.context.trim() : "";
      const maxRounds = Number.isInteger(args.maxRounds) && args.maxRounds > 0 ? Math.min(args.maxRounds, 10) : 5;

      // Cheap ideator set, all via vercel-ai-gateway (~$0.14-6.6/M vs fable's $22.5/M out).
      const DEFAULT_MODELS = [
        "vercel-ai-gateway/zai/glm-5.2-fast",
        "vercel-ai-gateway/deepseek/deepseek-v4-flash",
      ];
      // Judge needs reliable structured verdicts; user-picked kimi-k3-fast.
      const DEFAULT_JUDGE_MODEL = "vercel-ai-gateway/moonshotai/kimi-k3-fast";

      const models =
        Array.isArray(args.models) && args.models.length > 0 && args.models.every((m) => typeof m === "string" && m.trim())
          ? args.models.map((m) => m.trim())
          : DEFAULT_MODELS;
      const judgeModel = typeof args.judgeModel === "string" && args.judgeModel.trim() ? args.judgeModel.trim() : DEFAULT_JUDGE_MODEL;

      const IDEOLOGY =
        "You are an ideator in a multi-model debate. Propose ideas on their merits, attack weak points in others' positions, concede explicitly when an objection is answered, and merge positions when a synthesis is possible. Be concrete; no platitudes.";

      const contextBlock = context ? "\n\nBackground context: " + context : "";

      const transcript = [];
      let verdict = null;

      const discussionText = () => (transcript.length ? transcript : "(opening round — state your initial position)");

      for (let round = 1; round <= maxRounds; round++) {
        await phase("round-" + String(round) + "-chain");

        // Pass 1: sequential chain. Each ideator sees the transcript plus every
        // statement already made this round.
        const chain = [];
        for (const model of models) {
          const reply = await agent(
            prompt(
              "{brief}\n\nTopic under ideation: {topic}{context}\n\nDiscussion so far:\n{discussion}\n\nThis round, before you:\n{chain}\n\nEngage what was said before you this round — attack, defend, concede, or merge — then state your position. Under 200 words.",
              {
                brief: IDEOLOGY,
                topic,
                context: contextBlock,
                discussion: discussionText(),
                chain: chain.length ? chain : "(you speak first this round)",
              },
            ),
            { label: "chain-" + model + "-round-" + String(round), model },
          );
          chain.push({ model, reply });
        }
        transcript.push({ round, chain });

        // Pass 2: open floor. Everyone sees the full chain; each answers the
        // strongest objection to their own position.
        await phase("round-" + String(round) + "-floor");
        const floor = [];
        for (const model of models) {
          const reply = await agent(
            prompt(
              "{brief}\n\nTopic under ideation: {topic}{context}\n\nDiscussion so far:\n{discussion}\n\nThis round's exchange:\n{chain}\n\nIdentify the strongest objection to YOUR position from this round. Concede and revise, or counter it directly. Under 150 words.",
              { brief: IDEOLOGY, topic, context: contextBlock, discussion: transcript, chain },
            ),
            { label: "floor-" + model + "-round-" + String(round), model },
          );
          floor.push({ model, reply });
        }
        transcript.push({ round, floor });

        // Judge: structured consensus verdict.
        verdict = await agent(
          prompt(
            "You are the Consensus Judge. Topic: {topic}\n\nFull discussion:\n{discussion}\n\nDecide whether the ideators have converged on a shared position with no substantive unresolved disagreement. Different wording of the same position counts as converged. Open issues must be concrete disagreements, not stylistic notes.",
            { topic, discussion: transcript },
          ),
          {
            label: "judge-round-" + String(round),
            model: judgeModel,
            outputSchema: {
              type: "object",
              properties: {
                converged: { type: "boolean" },
                sharedPosition: { type: "string", description: "The agreed position in one paragraph, or the closest overlap if not converged." },
                openIssues: { type: "array", items: { type: "string" }, description: "Concrete unresolved disagreements; empty when converged." },
              },
              required: ["converged", "sharedPosition", "openIssues"],
              additionalProperties: false,
            },
          },
        );

        transcript.push({ round, judge: verdict.sharedPosition, openIssues: verdict.openIssues });

        if (verdict.converged) break;

        if (round === 3 && maxRounds > 3) {
          await checkpoint({
            name: "ideation-midpoint",
            prompt:
              "No consensus after 3 rounds on: " +
              topic.slice(0, 400) +
              ". Open issues: " +
              verdict.openIssues.slice(0, 5).join("; ").slice(0, 500) +
              ". Approve to continue, reject to stop and synthesize as-is.",
            context: { topic: topic.slice(0, 200), round, openIssues: verdict.openIssues.slice(0, 5).map((issue) => issue.slice(0, 300)) },
          });
        }
      }

      return await agent(
        prompt(
          "You are the Synthesizer. Topic: {topic}\n\nFull discussion:\n{discussion}\n\nFinal judge verdict: {verdict}\n\nProduce: 1) the agreed concept (or, if the judge never confirmed consensus, the strongest positions and why they diverge), 2) the key trade-offs, 3) concrete next steps. Be crisp.",
          { topic, discussion: transcript, verdict },
        ),
        { label: "synthesis", model: judgeModel },
      );
    '';
  };
}
