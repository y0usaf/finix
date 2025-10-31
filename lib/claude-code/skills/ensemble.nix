{
  name = "ensemble";
  description = "Orchestrate parallel headless Claude Code instances to decompose and parallelize large tasks. Use when you can split work into independent subtasks (code review, refactoring, analysis).";
  content = ''
    ---
    name: ensemble
    description: Orchestrate parallel headless Claude Code instances to decompose and parallelize large tasks. Use when you can split work into independent subtasks (code review, refactoring, analysis).
    ---

    # Ensemble: Parallel Execution

    ## Default: Parallel Task Calls (Preferred)

    **ALWAYS USE THIS FIRST**: For most parallel work, use multiple Task tool calls in a single message.

    Example - Analyzing 3 directories:
    ```
    <function_calls>
    <invoke name="Task">
      <parameter name="subagent_type">Explore</parameter>
      <parameter name="prompt">Analyze darwin/ for security issues</parameter>
    </invoke>
    <invoke name="Task">
      <parameter name="subagent_type">Explore</parameter>
      <parameter name="prompt">Analyze nixos/ for security issues</parameter>
    </invoke>
    <invoke name="Task">
      <parameter name="subagent_type">Explore</parameter>
      <parameter name="prompt">Analyze lib/ for security issues</parameter>
    </invoke>
    </function_calls>
    ```

    This is faster, cleaner, and integrates better with Claude Code's workflow.

    ## Advanced: Bash-Level Orchestration (Rare)

    Only use the bash orchestrator for:
    - Very large-scale parallelization (10+ workers)
    - Need for precise resource control
    - Offline/batch processing requirements

    ### Process

    1. **Analyze** the task - identify independent work
    2. **Decompose** into specific, well-scoped subtasks
    3. **Execute** the orchestrator script
    4. **Aggregate** results

    ## Implementation Pattern

    ```bash
    #!/bin/bash

    # Launch parallel headless Claude instances
    claude -p "Task 1: Specific focused work" > /tmp/worker1.log 2>&1 &
    PID1=$!

    claude -p "Task 2: Different focused work" > /tmp/worker2.log 2>&1 &
    PID2=$!

    claude -p "Task 3: Another focused work" > /tmp/worker3.log 2>&1 &
    PID3=$!

    # Wait for all to complete
    wait $PID1 $PID2 $PID3

    # Show results
    echo "=== Worker 1 ===" && cat /tmp/worker1.log
    echo "=== Worker 2 ===" && cat /tmp/worker2.log
    echo "=== Worker 3 ===" && cat /tmp/worker3.log
    ```

    ## Examples

    ### Code Review
    Task: Review 50 files across security, performance, and style

    ```bash
    claude -p "Review all files in src/ for security issues. Report vulnerabilities." > /tmp/security.log 2>&1 &
    claude -p "Review all files in src/ for performance issues. Report bottlenecks." > /tmp/perf.log 2>&1 &
    claude -p "Review all files in src/ for style issues. Report violations." > /tmp/style.log 2>&1 &
    wait
    ```

    ### Refactoring
    Task: Refactor authentication module

    ```bash
    claude -p "Refactor darwin/user/programs/browsers/handlers.nix - improve structure" > /tmp/handlers.log 2>&1 &
    claude -p "Refactor darwin/user/programs/browsers/models.nix - improve structure" > /tmp/models.log 2>&1 &
    claude -p "Refactor darwin/user/programs/browsers/utils.nix - improve structure" > /tmp/utils.log 2>&1 &
    wait
    ```

    ### Analysis
    Task: Analyze codebase for deprecated patterns

    ```bash
    claude -p "Analyze darwin/ for deprecated Nix patterns" > /tmp/darwin-analysis.log 2>&1 &
    claude -p "Analyze nixos/ for deprecated Nix patterns" > /tmp/nixos-analysis.log 2>&1 &
    claude -p "Analyze lib/ for deprecated Nix patterns" > /tmp/lib-analysis.log 2>&1 &
    wait
    ```

    ## Your Workflow

    1. User requests parallel work
    2. Decompose into independent tasks
    3. Write bash script with parallel `claude` commands
    4. Execute script using Bash tool with run_in_background=true
    5. Monitor with BashOutput tool
    6. Read all log files and synthesize results for user

    ## Guidelines

    - **Independence**: Only parallelize truly independent work (no shared files)
    - **Scope**: Each instance gets clear, non-overlapping scope
    - **Logs**: Each instance writes to separate log file
    - **Cleanup**: Remove temp logs after aggregation
    - **Errors**: Check exit codes, report failures clearly

    ## Anti-patterns

    - Don't parallelize tasks that modify the same files
    - Don't split trivial tasks that are faster done serially
    - Don't over-decompose (2-5 instances is usually optimal)
    - Don't use for tasks requiring coordination between instances
  '';
}
