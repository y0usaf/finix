# Shared no-test-authoring policy for every coding-agent harness.
#
# Single source of truth for the <tests> clause. Each harness injects
# config.user.dev.prompts.noTests through its own supported mechanism: the
# Hermes SOUL.md, codex developer_instructions, the opencode instruction files,
# and the omp/prime-agent APPEND_SYSTEM.md; the pi and phi agents receive it
# through the shared prompt body (modules/dev/ai/phi/prompt-body.nix), and the
# line process through ~/.config/slope/config.json's `system` key. Edit the
# clause here; consumers interpolate the option.
{lib, ...}: {
  options.user.dev.prompts.noTests = lib.mkOption {
    type = lib.types.lines;
    description = ''
      No-test-authoring policy shared by every coding-agent harness. The value
      carries no trailing newline so interpolation into a surrounding indented
      string cannot double the separator.
    '';
    # Moved verbatim from the <tests> block that was inline in
    # modules/dev/ai/phi/prompt-body.nix (lines 80-86). The closing '' stays on
    # the last content line to drop the trailing newline the inline block had.
    default = ''
      <tests>
        Unless explicitly requested, never create, add, propose, or plan tests of
        any kind, including fixtures, snapshots, golden files, test attributes,
        helpers, dependencies, or examples with test-like assertions. This applies
        to new and existing files. Disclose material verification gaps briefly
        and continue with the authorized work.
      </tests>'';
  };
}
