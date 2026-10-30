{
  config,
  flakeInputs,
  ...
}: let
  piSrc = "${flakeInputs.pi}/packages/coding-agent";
  body = config.user.dev.prompts.shared;
in {
  manzil.users."${config.user.name}".files = {
    ".config/phi/SYSTEM.md".text = "${body}\n";
    ".local/state/boar/agent/SYSTEM.md".text = "${body}\n";
    ".local/state/boar-rs/agent/SYSTEM.md".text = "${body}\n";
    ".pi/agent/SYSTEM.md".text = ''
      ${body}

      ## pi

      - Use one edit call per file, with every change in its `edits[]`.
      - Questions about pi itself: one doc per topic in ${piSrc}/docs
        (extensions, skills, themes, tui, sdk, models, packages and more),
        examples in ${piSrc}/examples. Resolve those paths there, never against
        the cwd.
    '';
  };
}
