{
  config,
  lib,
  flakeInputs,
  ...
}: let
  # Workflow packs for pi-workflows.
  #
  # Two sources, one runtime directory: the engine scans
  # <agentDir>/workflows/*/command.json and registers a slash command per
  # directory, so it cannot tell where a pack came from.
  #
  #   starters — generic packs versioned in pi-flake beside the engine. They
  #              assume a git repository and nothing else, so they are worth
  #              shipping to anyone who consumes that flake.
  #   personal — packs that name my PLAN.md, my `next` skill, my model
  #              aliases. Dead weight in a flake other people consume, so
  #              they live here and are placed from this tree.
  #
  # No JS is embedded in Nix in either case; this module only places files.
  starterSource = "${flakeInputs.pi-flake}/workflows";
  personalSource = ./workflows;
  workflowRoot = ".local/share/pi/agent/workflows";

  # directory -> entry script named by its command.json
  starters = {
    pie = "pie.js";
    review = "review.js";
    debug = "debug.js";
  };

  personal = {
    ideation = "ideate.js";
    loop-next = "loop-next.js";
  };

  packFiles = source: packs:
    lib.listToAttrs (
      lib.concatLists (
        lib.mapAttrsToList (dir: script: [
          (lib.nameValuePair "${workflowRoot}/${dir}/command.json" {
            source = source + "/${dir}/command.json";
          })
          (lib.nameValuePair "${workflowRoot}/${dir}/${script}" {
            source = source + "/${dir}/${script}";
          })
        ])
        packs
      )
    );
in {
  config = lib.mkIf config.user.dev.pi.enable {
    manzil.users."${config.user.name}".files =
      packFiles starterSource starters
      // packFiles personalSource personal;
  };
}
