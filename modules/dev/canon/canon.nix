{
  config,
  lib,
  ...
}: {
  options.user.dev.canon = {
    enable = lib.mkEnableOption "~/dev design canon as AGENTS.md";
  };

  config = lib.mkIf config.user.dev.canon.enable {
    manzil.users."${config.user.name}".files = {
      # Stored as canon.md, deployed as AGENTS.md. Agents collect every
      # AGENTS.md walking up from cwd, so a file with that name living here
      # would inject the ~/dev canon into this repo — which the canon's own
      # scope rule excludes. Renaming the source keeps the scope boundary at
      # ~/dev, where the target symlink is the only AGENTS.md.
      "dev/AGENTS.md".source = ./canon.md;
    };
  };
}
