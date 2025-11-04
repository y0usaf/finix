{
  name = "ensemble";
  description = "Default approach: parallelize all independent work. Use headless Claude Code to run multiple tasks simultaneously. Each instance runs independently with full tool access and context isolation.";
  content = ''
    ---
    name: ensemble
    description: Default approach: parallelize all independent work. Use headless Claude Code to run multiple tasks simultaneously. Each instance runs independently with full tool access and context isolation.
    ---

    # Ensemble: Parallel Execution Pattern

    **Ensemble is your default strategy.** Always parallelize independent work using headless Claude Code instances.

    ## Core Pattern: Headless Claude Code with Background Jobs

    Launch multiple `claude -p` instances that run in parallel:

    ```bash
    #!/bin/bash
    # Parallel task execution pattern

    claude -p "Task 1: Analyze darwin/ for configuration patterns" > /tmp/task1.txt 2>&1 &
    PID1=$!

    claude -p "Task 2: Analyze nixos/ for configuration patterns" > /tmp/task2.txt 2>&1 &
    PID2=$!

    claude -p "Task 3: Search codebase for redundancy" > /tmp/task3.txt 2>&1 &
    PID3=$!

    # Wait for all tasks to complete
    wait $PID1 $PID2 $PID3

    # Aggregate results
    echo "=== Task 1 ===" && cat /tmp/task1.txt
    echo "=== Task 2 ===" && cat /tmp/task2.txt
    echo "=== Task 3 ===" && cat /tmp/task3.txt
    ```

    ## With Tool Restrictions (Optional)

    Limit tools if a task doesn't need all capabilities:

    ```bash
    claude -p "Security audit of configs" --allowedTools "Read,Grep" > /tmp/security.txt 2>&1 &
    claude -p "Performance analysis" --allowedTools "Read,Bash,Grep" > /tmp/performance.txt 2>&1 &
    wait
    ```

    ## Handling Dependencies Within Parallel Tasks

    If one task has internal dependencies, structure it sequentially within the single parallel instance:

    ```bash
    claude -p "
    Task A (with dependencies):
    1. Search for pattern X in codebase
    2. Analyze results from step 1
    3. Return consolidated findings

    Return: [findings]
    " > /tmp/dependent.txt 2>&1 &

    claude -p "
    Task B (independent):
    Analyze lib/ structure
    Return: [structure analysis]
    " > /tmp/independent.txt 2>&1 &

    wait
    ```

    ## When to Use

    - Multi-directory analysis (darwin/, nixos/, lib/)
    - Independent code reviews (security, performance, style)
    - Parallel searches or pattern matching
    - Independent refactoring tasks
    - Any 2+ non-dependent pieces of work

    ## Key Advantage

    Parallel execution dramatically reduces total time:
    - Sequential: Task A (5 min) + Task B (5 min) + Task C (5 min) = **15 minutes**
    - Parallel: All run simultaneously = **~5 minutes total**

    **Always use ensemble. It's the fastest approach.**
  '';
}
