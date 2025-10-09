{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.jj = {
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
  config = lib.mkIf config.user.tools.jj.enable {
    environment.systemPackages = [
      pkgs.jujutsu
    ];
    usr = {
      files =
        {
          ".config/jj/config.toml" = {
            text = ''
              [user]
              name = "${config.user.tools.jj.name}"
              email = "${config.user.tools.jj.email}"
              [ui]
              default-command = "status"
              editor = "${config.user.tools.jj.editor}"
              diff-editor = "${config.user.tools.jj.editor}"
              [git]
              auto-local-branch = true
              push-branch-prefix = ""
              [revset-aliases]
              "mine" = "author(${config.user.tools.jj.email})"
              "recent" = "heads(::@ & recent(5))"
              ${lib.optionalString config.user.tools.jj.enableAliases ''
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
        // lib.optionalAttrs config.user.tools.jj.enableAliases {
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
