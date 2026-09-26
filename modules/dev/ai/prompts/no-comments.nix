{lib, ...}: {
  options.user.dev.prompts.noComments = lib.mkOption {
    type = lib.types.lines;
    description = ''
      No-comment policy shared by every coding-agent harness. The value carries
      no trailing newline so interpolation into a surrounding indented string
      cannot double the separator.
    '';
    default = ''
      <comments>
        Never write code comments. Delete any existing comment your change makes wrong.
      </comments>'';
  };
}
