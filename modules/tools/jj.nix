{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkEnableOption mkIf mkAfter optionalString optionalAttrs;
  cfg = config.user.tools.jj;
in {
  options.user.tools.jj = {
    enable = mkEnableOption "jujutsu version control system";
    name = mkOption {
      type = types.str;
      description = "Jujutsu username.";
    };
    email = mkOption {
      type = types.str;
      description = "Jujutsu email address.";
    };
    editor = mkOption {
      type = types.str;
      default = "nvim";
      description = "Default editor for jujutsu.";
    };
    enableAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Enable common jujutsu aliases.";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.jujutsu
    ];
    manzil.users."${config.user.name}".files =
      {
        ".config/jj/config.toml" = {
          text = ''
            [user]
            name = "${cfg.name}"
            email = "${cfg.email}"
            [ui]
            default-command = "status"
            editor = "${cfg.editor}"
            diff-editor = "${cfg.editor}"
            [git]
            auto-local-branch = true
            push-branch-prefix = ""
            [revset-aliases]
            "mine" = "author(${cfg.email})"
            "recent" = "heads(::@ & recent(5))"
            ${optionalString cfg.enableAliases ''
              [aliases]
              l = ["log", "-r", "recent"]
              ll = ["log", "-r", "::@"]
              s = ["status"]
              d = ["diff"]
              c = ["commit"]
              ca = ["commit", "--amend"]
              co = ["checkout"]
              n = ["new"]
              e = ["edit"]
              b = ["branch"]
              rb = ["rebase"]
              sp = ["split"]
              sq = ["squash"]
            ''}
          '';
        };
      }
      // optionalAttrs (cfg.enableAliases && (lib.attrByPath ["user" "shell" "zsh" "enable"] false config)) {
        ".config/zsh/.zshrc" = {
          text = ''
            alias jl='jj log -r recent'
            alias jll='jj log -r ::@'
            alias js='jj status'
            alias jd='jj diff'
            alias jc='jj commit'
            alias jca='jj commit --amend'
            alias jco='jj checkout'
            alias jn='jj new'
            alias je='jj edit'
            alias jb='jj branch'
            alias jrb='jj rebase'
            alias jsp='jj split'
            alias jsq='jj squash'
          '';
        };
      }
      // optionalAttrs (cfg.enableAliases && (lib.attrByPath ["user" "shell" "nushell" "enable"] false config)) {
        ".config/nushell/config.nu" = {
          text = mkAfter ''
            alias jl = jj log -r recent
            alias jll = jj log -r ::@
            alias js = jj status
            alias jd = jj diff
            alias jc = jj commit
            alias jca = jj commit --amend
            alias jco = jj checkout
            alias jn = jj new
            alias je = jj edit
            alias jb = jj branch
            alias jrb = jj rebase
            alias jsp = jj split
            alias jsq = jj squash
          '';
        };
      };
  };
}
