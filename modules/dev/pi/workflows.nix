{
  config,
  lib,
  flakeInputs,
  ...
}: let
  # Workflow scripts for pi-extensible-workflows.
  #
  # Source of truth is pi-flake's workflows/ tree (real .js files, linted by
  # biome, versioned alongside the vendored engine). This module only *places*
  # them: the engine scans <agentDir>/workflows/*/command.json and registers a
  # slash command per directory, so a workflow shipped here gets /<name> for
  # free. No JS is embedded in Nix, so the two copies cannot drift.
  workflowSource = "${flakeInputs.pi-flake}/workflows";
  workflowRoot = ".local/share/pi/agent/workflows";

  # directory in pi-flake/workflows/ -> entry script named by its command.json
  workflows = {
    ideation = "ideate.js";
    loop-next = "loop-next.js";
  };

  workflowFile = dir: name:
    lib.nameValuePair "${workflowRoot}/${dir}/${name}" {
      source = "${workflowSource}/${dir}/${name}";
    };

  workflowFiles = lib.listToAttrs (
    lib.concatLists (
      lib.mapAttrsToList (dir: script: [
        (workflowFile dir "command.json")
        (workflowFile dir script)
      ])
      workflows
    )
  );
in {
  config = lib.mkIf config.user.dev.pi.enable {
    manzil.users."${config.user.name}".files = workflowFiles;
  };
}
