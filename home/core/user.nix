#═══════════════════════════ 🔧 USER CONFIGURATION MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  inputs,
  hostSystem,
  hostHome,
  ...
}: let
  helpers = import ../../lib/helpers/module-defs.nix {inherit lib;};
  inherit (helpers) t mkOpt mkOptDef mkStr;
in {
  options.cfg.user = {
    packages = lib.mkOption {
      type = t.listOf t.package;
      default = [];
      description = "List of additional user-specific packages.";
    };

    # User-specific settings (bookmarks, git)
    bookmarks = mkOptDef (t.listOf mkStr) (hostHome.cfg.user.bookmarks or []) "GTK bookmarks";
    git = mkOptDef (t.submodule {
      options = {
        name = mkOpt mkStr "Git user name";
        email = mkOpt mkStr "Git user email";
        homeManagerRepoUrl = mkOpt mkStr "URL to home manager repository";
      };
    }) (hostHome.cfg.tools.git or {}) "Git configuration";
  };
}
