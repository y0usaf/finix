# Instructify rules — migrated from collab-flow, todowrite-instruct, teams-instruct
builtins.toJSON {
  agentic-terminal-instruct = {
    events = ["UserPromptSubmit"];
    instruction = ''
      MANDATORY: If you are about to tell the user to run a terminal command that you can run agentically, run it yourself instead.
      Only ask the user to run commands when execution is blocked by missing permissions, missing credentials, unavailable local environment, or explicit user preference.'';
  };

  teams-instruct = {
    events = ["SessionStart"];
    instruction = ''
      MANDATORY: Use Agent Teams for ALL tasks. Never work alone when teammates can parallelize the effort.

      Workflow:
      1. TeamCreate -> create a team
      2. TaskCreate -> break work into subtasks
      3. Task tool (with team_name and name params) -> spawn teammates
      4. TaskUpdate (with owner param) -> assign tasks to teammates
      5. SendMessage type: "shutdown_request" -> when all work is complete
      6. TeamDelete -> clean up

      Always break work into parallel subtasks and delegate to teammates.'';
  };
}
