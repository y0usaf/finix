args: let
  moduleMode = args.moduleMode or true;
  skill = {
    skill = ''
      ---
      name: linear-cli
      description: Use when Codex needs to work with Linear through the schpet/linear-cli package available via bunx. This skill exposes the verified command entrypoint, authentication flow, and common command groups for tasks such as listing or updating issues, working with teams, projects, cycles, labels, documents, initiatives, project updates, raw GraphQL API queries, or generating completions/configuration.
      ---

      # Linear CLI

      ## Overview

      Use the `schpet/linear-cli` package through `bunx` instead of reimplementing Linear operations manually.
      Prefer CLI calls for direct Linear reads or mutations when the task maps cleanly to the available commands.

      ## Entry Point

      Run the CLI with:

      ```bash
      bunx --yes @schpet/linear-cli <command> [args]
      ```

      Verified help output shows the executable name as `linear`.

      ## Authentication

      Authenticate first when needed:

      ```bash
      bunx --yes @schpet/linear-cli auth
      ```

      Use `-w, --workspace <slug>` to target a specific workspace when the task is not using the default credentials.

      ## Command Groups

      - `issue` / `i`
      - `team` / `t`
      - `project` / `p`
      - `project-update` / `pu`
      - `cycle` / `cy`
      - `milestone` / `m`
      - `initiative` / `init`
      - `initiative-update` / `iu`
      - `label` / `l`
      - `document` / `docs` / `doc`
      - `api`
      - `schema`
      - `config`
      - `completions`

      ## Working Style

      Start with `--help` on the relevant command if the exact subcommand shape is unclear.

      Examples:

      ```bash
      bunx --yes @schpet/linear-cli issue --help
      bunx --yes @schpet/linear-cli project --help
      bunx --yes @schpet/linear-cli api 'query { viewer { id name } }'
      ```

      If the CLI covers the task, prefer using it directly. Fall back to other approaches only when the needed Linear operation is not exposed or the environment is not authenticated.
    '';

    interface = {
      display_name = "Linear CLI";
      short_description = "Expose Linear CLI via bunx";
      default_prompt = "Use $linear-cli to work with Linear from the command line via bunx.";
    };
  };
in
  if moduleMode
  then {
    config.lib.ai.skills.linear-cli = skill;
  }
  else skill
