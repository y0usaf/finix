args: let
  skill = {
    requiresAgentSlack = true;

    skill = ''
      ---
      name: agent-slack
      description: Use when Codex needs to work with Slack through the locally installed agent-slack CLI. This skill exposes the available command entrypoint, authentication flow, and common command groups for tasks such as reading or sending messages, searching Slack, working with canvases, looking up users, or managing channels.
      ---

      # Agent Slack

      ## Overview

      Use the `agent-slack` CLI for Slack work instead of a Slack MCP server or manual API calls.
      Prefer the installed `agent-slack` binary when `user.dev.agent-slack.enable` is on.

      ## Entry Point

      Run the CLI with:

      ```bash
      agent-slack <command> [args]
      ```

      Verified help output describes it as "Slack automation CLI for AI agents".

      ## Authentication

      Authenticate first when needed:

      ```bash
      agent-slack auth
      ```

      ## Command Groups

      - `message`
      - `canvas`
      - `search`
      - `user`
      - `channel`
      - `update`

      ## Working Style

      Start with `--help` on the relevant command if the exact subcommand shape is unclear.

      Examples:

      ```bash
      agent-slack message --help
      agent-slack search --help
      agent-slack channel --help
      ```

      If the CLI covers the task, prefer using it directly. Fall back to other approaches only when the needed Slack operation is not exposed or the environment is not authenticated.
    '';

    interface = {
      display_name = "Agent Slack";
      short_description = "Expose Slack CLI locally";
      default_prompt = "Use $agent-slack to work with Slack through the local agent-slack CLI.";
    };
  };
in
  if (args.moduleMode or true)
  then {
    config.lib.ai.skills.agent-slack = skill;
  }
  else skill
