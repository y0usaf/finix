# Shared no-test-authoring policy for every coding-agent harness.
#
# Single source of truth for the <tests> clause. Each harness injects
# config.user.dev.prompts.noTests through its own supported mechanism: the
# Hermes SOUL.md, codex developer_instructions, the opencode instruction files,
# and the omp/prime-agent APPEND_SYSTEM.md; the pi and phi agents receive it
# through the shared prompt body (modules/dev/ai/phi/prompt-body.nix). Edit the
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
        Unless explicitly requested, never create, add, propose, or plan tests,
        fixtures, snapshots, golden files, or test helpers. Exception: end-to-end
        tests that drive the built artifact through its public interface (CLI,
        socket, HTTP, NixOS VM) with no mocks, and run under `nix flake check`.
        Add one only when it covers behaviour a user would notice. Disclose
        material verification gaps briefly and continue with the authorized work.
      </tests>'';
  };
}
