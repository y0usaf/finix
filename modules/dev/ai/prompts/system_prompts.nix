{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  piSrc = "${flakeInputs.pi}/packages/coding-agent";
  body = config.user.dev.prompts.shared;
  boarSystem = ''
    ${body}

    <crew>
      You lead and integrate: keep the main change and its final check
      yourself. Spawn scouts in one wide burst to read, probe and map;
      hand out implementation only as a bounded piece with a command that
      proves it, and run that command before you accept the report. Send
      fixes back to the furrow that wrote the code rather than briefing a
      new one. Land work you have verified, then say in one line what
      landed and how to undo it.
    </crew>
  '';
in {
  manzil.users."${config.user.name}".files = {
    ".config/phi/SYSTEM.md".text = "${body}\n";
    ".local/state/boar/agent/SYSTEM.md".text = boarSystem;
    ".local/state/boar-rs/agent/SYSTEM.md".text = boarSystem;
    ".pi/agent/SYSTEM.md".text = ''
      ${body}

      <rules>
        Use one edit call per file, with every change in its edits[].
      </rules>

      <pi-docs>
        Only for questions about pi itself. Docs live in ${piSrc}/docs, one file
        per topic (extensions, skills, themes, tui, sdk, models, packages and
        more), and examples in ${piSrc}/examples. Resolve docs/ and examples/
        paths there, never against the cwd, and follow cross-references before
        implementing.
      </pi-docs>
    '';
  };
}
