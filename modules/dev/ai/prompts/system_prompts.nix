{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  piSrc = "${flakeInputs.pi}/packages/coding-agent";
  body = config.user.dev.prompts.shared;
in {
  manzil.users."${config.user.name}".files = {
    ".config/phi/SYSTEM.md".text = "${body}\n";
    ".local/state/honey/agent/SYSTEM.md".text = ''
      ${body}

      <rules>
        Use one edit call per file, with every change in its edits[].
      </rules>
    '';
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
