# Instructify rules — migrated from collab-flow, todowrite-instruct, teams-instruct
builtins.toJSON {
  collab-flow = {
    events = ["UserPromptSubmit"];
    instruction = "MANDATORY: Use AskUserQuestion before proceeding.";
  };

  todowrite-instruct = {
    events = ["UserPromptSubmit"];
    instruction = "MANDATORY: Use TaskCreate before proceeding.";
  };

  teams-instruct = {
    events = ["UserPromptSubmit"];
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
