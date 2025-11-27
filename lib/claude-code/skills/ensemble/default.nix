# Ensemble skill - multi-backend parallel worker orchestration
{
  # The skill content (markdown) that gets loaded when skill is invoked
  content = ''
    ---
    name: ensemble
    description: Run parallel Claude workers for multi-perspective analysis. Use for code reviews, codebase exploration, debugging, or any task benefiting from diverse perspectives.
    ---

    # Ensemble Skill

    You orchestrate a heterogeneous ensemble of parallel workers across multiple backends.

    ## Backend Syntax

    Use `--backend=provider:count,...` to specify workers:

    ```
    --backend=claude:3                    # 3 Claude workers
    --backend=claude:2,codex:2            # 2 Claude + 2 Codex (parallel)
    --backend=claude:3,codex:2,gemini:1   # Multi-provider ensemble
    ```

    **IMPORTANT: No defaults. Worker count is always required.**

    ## Available Backends

    | Backend | How You Invoke It | Notes |
    |---------|-------------------|-------|
    | `claude` | Bash: `~/.claude/scripts/ensemble.sh --workers=N "task"` | Recursive (can spawn sub-ensembles) |
    | `codex` | MCP: `mcp__codex__codex` | GPT models, different perspective |
    | `gemini` | MCP: (when available) | Future extensibility |

    ## CRITICAL: Parallel Invocation

    You MUST invoke all backends in a **SINGLE MESSAGE** with parallel tool calls.

    **Correct (parallel):**
    ```
    User: "ensemble --backend=claude:2,codex:2 analyze auth"

    You send ONE message with:
    ├── Bash: ~/.claude/scripts/ensemble.sh --workers=2 "analyze auth"
    ├── mcp__codex__codex: "analyze auth"
    └── mcp__codex__codex: "analyze auth"
    ```

    **WRONG (sequential):**
    ```
    Message 1: Bash ensemble.sh...
    Message 2: mcp__codex__codex...
    Message 3: mcp__codex__codex...
    ```

    Sequential invocation defeats the purpose. All workers MUST run simultaneously.

    ## Per-Worker Tasks

    For specialized analysis, assign different tasks:

    ```
    --backend=claude:3 \
      --worker-1="security vulnerabilities" \
      --worker-2="performance bottlenecks" \
      --worker-3="code maintainability"
    ```

    For Codex workers in the same ensemble, vary the prompts in your MCP calls.

    ## Output Format

    Claude workers return XML:
    ```xml
    <ensemble-output workers="2" model="claude-haiku-4-5">
      <worker id="1" status="success" task="...">...</worker>
      <worker id="2" status="success" task="...">...</worker>
    </ensemble-output>
    ```

    Codex workers return plain text responses.

    ## Your Role as Orchestrator

    1. **Parse** the `--backend=` specification
    2. **Invoke** all backends in ONE parallel message
    3. **Collect** results from all workers
    4. **Synthesize** - combine insights, deduplicate, prioritize
    5. **Report** - unified response to user

    ## Example

    User: "ensemble --backend=claude:2,codex:1 review the auth system"

    You send ONE message:
    ```
    Tool 1: Bash
      ~/.claude/scripts/ensemble.sh --workers=2 \
        --worker-1="security analysis of auth" \
        --worker-2="session management review" \
        "auth system review"

    Tool 2: mcp__codex__codex
      prompt: "Review the auth system for vulnerabilities and best practices"
    ```

    Then synthesize all 3 perspectives into a unified review.

    ## Recursion

    Claude workers can spawn sub-ensembles (bash script calls are recursive).
    Codex workers are leaf nodes (no sub-spawning).

    Use recursion for deep exploration:
    ```
    Worker 1 → finds auth module → spawns sub-ensemble on auth
    Worker 2 → finds API layer → spawns sub-ensemble on API
    ```
  '';
}
