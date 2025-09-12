{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.jj;
in {
  options.home.tools.jj = {
    enable = lib.mkEnableOption "jujutsu version control system";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Jujutsu username.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Jujutsu email address.";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor for jujutsu.";
    };
    enableAliases = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable common jujutsu aliases.";
    };
  };
  config = lib.mkIf cfg.enable {
    usr = {
      packages = with pkgs; [
        jujutsu
      ];
      files =
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
              ${lib.optionalString cfg.enableAliases ''
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
            clobber = true;
          };
        }
        // lib.optionalAttrs cfg.enableAliases {
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
            clobber = true;
          };
        };
    };
  };
}
