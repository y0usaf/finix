# Neovim injections for Nix files
{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/after/queries/nix/injections.scm".text = ''
      ; extends
      (
        (assignment
          left: (attr_path_expression) @path
          right: (indented_string_expression
            (string_fragment) @injection.content
          )
        )
        (#match? @path "\\.text$")
        (#any-of? @injection.content "^--.*" "^local " "^vim%.")
        (#set! injection.language "lua")
      )

      (
        (assignment
          left: (attr_path_expression) @path
          right: (string_expression
            (string_fragment) @injection.content
          )
        )
        (#match? @path "\\.text$")
        (#any-of? @injection.content "^--.*" "^local " "^vim%.")
        (#set! injection.language "lua")
      )
    '';
  };
}
