# Instructify rules — migrated from collab-flow, todowrite-instruct, teams-instruct
builtins.toJSON {
  agentic-terminal-instruct = {
    events = ["UserPromptSubmit"];
    instruction = ''
      MANDATORY: If you are about to tell the user to run a terminal command that you can run agentically, run it yourself instead.
      Only ask the user to run commands when execution is blocked by missing permissions, missing credentials, unavailable local environment, or explicit user preference.'';
  };
}
