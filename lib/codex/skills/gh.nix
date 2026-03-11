{
  requiresGh = true;

  skill = ''
    ---
    name: gh
    description: Use when Codex needs to work with GitHub through the installed gh CLI. This skill exposes the verified command entrypoint, authentication flow, and major command groups for tasks such as issues, pull requests, repositories, projects, releases, workflow runs, search, API requests, and GitHub status queries.
    ---

    # GitHub CLI

    ## Overview

    Use the installed `gh` CLI for GitHub work instead of manual API calls when the task maps to a CLI command.
    Prefer `gh` when `user.tools.gh.enable` is on.

    ## Entry Point

    Run the CLI with:

    ```bash
    gh <command> <subcommand> [flags]
    ```

    Verified help output describes it as working seamlessly with GitHub from the command line.

    ## Authentication

    Authenticate first when needed:

    ```bash
    gh auth login
    gh auth status
    ```

    ## Command Groups

    - `issue`
    - `pr`
    - `repo`
    - `project`
    - `release`
    - `workflow`
    - `run`
    - `search`
    - `api`
    - `status`
    - `browse`
    - `gist`
    - `secret`
    - `variable`

    ## Working Style

    Start with `--help` on the relevant command if the exact subcommand shape is unclear.

    Examples:

    ```bash
    gh issue --help
    gh pr --help
    gh repo view
    gh api user
    ```

    If the CLI covers the task, prefer using it directly. Fall back to other approaches only when the needed GitHub operation is not exposed or the environment is not authenticated.
  '';

  interface = {
    display_name = "GitHub CLI";
    short_description = "Expose gh locally";
    default_prompt = "Use $gh to work with GitHub through the installed gh CLI.";
  };
}
