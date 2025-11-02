{
  name = "ensemble";
  description = "Parallelize independent subtasks using multiple Task agents in a single message.";
  content = ''
    ---
    name: ensemble
    description: Parallelize independent subtasks using multiple Task agents in a single message.
    ---

    # Ensemble: Parallel Subtasks

    For independent work, you can parallelize using headless Claude Code instances.

    ## Quick: Multiple Task Calls

    Make multiple Task calls in one message—they execute in parallel:

    ```xml
    <function_calls>
    <invoke name="Task">
      <parameter name="description">Analyze darwin/</parameter>
      <parameter name="prompt">Review darwin/ for issues</parameter>
      <parameter name="subagent_type">Explore</parameter>
    </invoke>
    <invoke name="Task">
      <parameter name="description">Analyze nixos/</parameter>
      <parameter name="prompt">Review nixos/ for issues</parameter>
      <parameter name="subagent_type">Explore</parameter>
    </invoke>
    </function_calls>
    ```

    ## Full Parallelization: Headless Claude Code

    For true parallel execution, launch headless Claude Code instances:

    ```bash
    #!/bin/bash
    claude -p "Analyze darwin/ for security issues" > /tmp/darwin.log 2>&1 &
    claude -p "Analyze nixos/ for performance issues" > /tmp/nixos.log 2>&1 &
    claude -p "Analyze lib/ for style issues" > /tmp/lib.log 2>&1 &
    wait
    cat /tmp/{darwin,nixos,lib}.log
    ```

    Use headless instances when tasks are large, complex, or need full isolation.
  '';
}
