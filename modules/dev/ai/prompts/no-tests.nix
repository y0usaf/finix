{lib, ...}: {
  options.user.dev.prompts.noTests = lib.mkOption {
    type = lib.types.lines;
    description = ''
      No-test-authoring policy shared by every coding-agent harness. The value
      carries no trailing newline so interpolation into a surrounding indented
      string cannot double the separator.
    '';
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
